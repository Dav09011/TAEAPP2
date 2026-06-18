import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_branch_summary.dart';
import 'package:tae_app/features/student/domain/entities/student_wallet_group_membership.dart';
import 'package:tae_app/features/student/domain/repositories/student_wallet_repository.dart';

class FirebaseStudentWalletRepository implements StudentWalletRepository {
  FirebaseStudentWalletRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Stream<List<StudentWalletBranchSummary>> watchWalletBranches() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<List<StudentWalletBranchSummary>>.empty();
    }

    return _firestoreService.users().doc(uid).snapshots().asyncMap((
      snapshot,
    ) async {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final groups = _parseGroups(data);
      final branchCandidates = _parseBranchCandidates(data, groups);
      final preferences = _parsePreferences(data);
      final pendingRequests = await _loadPendingRequests(uid);

      final summaries = <StudentWalletBranchSummary>[];
      for (final candidate in branchCandidates) {
        try {
          final resolvedBranchId = await _resolveBranchId(
            candidate.rawBranchToken,
          );
          if (resolvedBranchId.isEmpty) continue;

          final resolvedBranch = await _loadBranchInfo(resolvedBranchId);
          if (resolvedBranch == null) continue;

          final tariffs = await _loadTariffsSafely(
            resolvedBranch.adminId,
            resolvedBranch.branchId,
            branchName: resolvedBranch.branchName,
          );
          final pref = preferences[resolvedBranch.branchId];
          final matchingGroups = _groupsForBranch(
            groups,
            resolvedBranch.branchId,
            resolvedBranch.branchName,
            candidate.rawBranchToken,
          );
          final branchPendingRequest =
              pendingRequests
                  .where(
                    (request) => request.branchId == resolvedBranch.branchId,
                  )
                  .toList();
          final pendingRequest =
              branchPendingRequest.isNotEmpty
                  ? branchPendingRequest.first
                  : null;

          summaries.add(
            StudentWalletBranchSummary(
              branchId: resolvedBranch.branchId,
              branchName: resolvedBranch.branchName,
              adminId: resolvedBranch.adminId,
              groups:
                  matchingGroups.map((item) => item.toMembership()).toList(),
              availableTariffs: tariffs,
              hasPendingCashRequest: pendingRequest != null,
              branchColorValue: resolvedBranch.branchColorValue,
              currentTariffId: pref?.currentTariffId,
              currentTariffName: pref?.currentTariffName,
              currentTariffAmountCents: pref?.currentTariffAmountCents,
              currentTariffPeriodType: pref?.currentTariffPeriodType,
              currentTariffPeriodCount: pref?.currentTariffPeriodCount,
              pendingTariffId: pref?.pendingTariffId,
              pendingTariffName: pref?.pendingTariffName,
              pendingTariffAmountCents: pref?.pendingTariffAmountCents,
              pendingTariffPeriodType: pref?.pendingTariffPeriodType,
              pendingTariffPeriodCount: pref?.pendingTariffPeriodCount,
              pendingCashRequestId: pendingRequest?.id,
            ),
          );
        } catch (_) {
          continue;
        }
      }

      return summaries;
    });
  }

  @override
  Future<List<PaymentTariff>> loadAvailableTariffs(String branchId) async {
    final resolved = await _loadBranchInfo(branchId);
    if (resolved == null) {
      return const [];
    }

    return _loadTariffsSafely(
      resolved.adminId,
      resolved.branchId,
      branchName: resolved.branchName,
    );
  }

  Future<List<PaymentTariff>> _loadTariffsSafely(
    String adminId,
    String branchId, {
    String? branchName,
  }) async {
    try {
      final snapshot =
          await _firestoreService.adminPaymentTariffs(adminId).get();
      final normalizedBranchId = branchId.trim().toLowerCase();
      final normalizedBranchName = (branchName ?? '').trim().toLowerCase();

      final tariffs =
          snapshot.docs
              .map((doc) => PaymentTariff.fromMap(doc.id, doc.data()))
              .where((tariff) {
                final tariffBranch = tariff.branchId.trim().toLowerCase();
                final matchesBranch =
                    tariffBranch == normalizedBranchId ||
                    (normalizedBranchName.isNotEmpty &&
                        tariffBranch == normalizedBranchName);
                return tariff.isActive && matchesBranch;
              })
              .toList();

      tariffs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tariffs;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> setPendingTariff({
    required String branchId,
    required String tariffId,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final resolved = await _loadBranchInfo(branchId);
    if (resolved == null) {
      throw const AppException('No se encontro la sucursal.');
    }

    final tariff =
        await _firestoreService
            .adminPaymentTariffs(resolved.adminId)
            .doc(tariffId)
            .get();
    final tariffData = tariff.data();
    if (tariffData == null) {
      throw const AppException('No se encontro la tarifa seleccionada.');
    }

    await _firestoreService.instance.runTransaction((transaction) async {
      final profileRef = _firestoreService.users().doc(uid);
      final profileSnapshot = await transaction.get(profileRef);
      final currentPreferences =
          _parsePreferences(profileSnapshot.data() ?? {});
      final existing = currentPreferences[branchId];

      currentPreferences[branchId] = _WalletPreference(
        branchId: branchId,
        branchName: resolved.branchName,
        currentTariffId: existing?.currentTariffId,
        currentTariffName: existing?.currentTariffName,
        currentTariffAmountCents: existing?.currentTariffAmountCents,
        currentTariffPeriodType: existing?.currentTariffPeriodType,
        currentTariffPeriodCount: existing?.currentTariffPeriodCount,
        pendingTariffId: tariffId,
        pendingTariffName: tariffData['name'] as String? ?? 'Sin nombre',
        pendingTariffAmountCents: (tariffData['amount_cents'] as num?)?.toInt(),
        pendingTariffPeriodType: tariffData['period_type'] as String?,
        pendingTariffPeriodCount: (tariffData['period_count'] as num?)?.toInt(),
        updatedAt: DateTime.now(),
      );

      transaction.set(
        profileRef,
        {
          'wallet_preferences':
              currentPreferences.values.map((pref) => pref.toMap()).toList(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> clearPendingTariff(String branchId) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    await _firestoreService.instance.runTransaction((transaction) async {
      final profileRef = _firestoreService.users().doc(uid);
      final profileSnapshot = await transaction.get(profileRef);
      final preferences = _parsePreferences(profileSnapshot.data() ?? {});
      final pref = preferences[branchId];
      if (pref == null) return;

      preferences[branchId] = _WalletPreference(
        branchId: pref.branchId,
        branchName: pref.branchName,
        currentTariffId: pref.currentTariffId,
        currentTariffName: pref.currentTariffName,
        currentTariffAmountCents: pref.currentTariffAmountCents,
        currentTariffPeriodType: pref.currentTariffPeriodType,
        currentTariffPeriodCount: pref.currentTariffPeriodCount,
        updatedAt: DateTime.now(),
      );

      transaction.set(
        profileRef,
        {
          'wallet_preferences':
              preferences.values.map((value) => value.toMap()).toList(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<String> createCashPaymentRequest({
    required String branchId,
    required String groupId,
    required String tariffId,
    required String tariffName,
    required int amountCents,
    String? note,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final resolved = await _loadBranchInfo(branchId);
    if (resolved == null) {
      throw const AppException('No se encontro la sucursal.');
    }

    final tariffSnapshot =
        await _firestoreService
            .adminPaymentTariffs(resolved.adminId)
            .doc(tariffId)
            .get();
    final tariffData = tariffSnapshot.data();
    if (tariffData == null) {
      throw const AppException('No se encontro la tarifa seleccionada.');
    }

    final profileSnapshot = await _firestoreService.users().doc(uid).get();
    final profileData = profileSnapshot.data() ?? const <String, dynamic>{};
    final group =
        _resolveGroupById(profileData, groupId) ??
        _resolvePrimaryGroup(profileData, branchId);
    final now = DateTime.now();
    final requestRef = _firestoreService.cashPaymentRequests().doc();
    await requestRef.set({
      'uid': uid,
      'student_id': uid,
      'student_name': _studentFullName(profileData),
      'admin_id': resolved.adminId,
      'branch_id': branchId,
      'branch_name': resolved.branchName,
      'group_id': group.groupId,
      'group_name': group.groupName,
      'tariff_id': tariffId,
      'tariff_name': tariffName,
      'amount_cents': amountCents,
      'currency': 'mxn',
      'period_type': tariffData['period_type'] as String? ?? 'month',
      'period_count': (tariffData['period_count'] as num?)?.toInt() ?? 1,
      'status': 'pending',
      'note': note,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'reviewed_at': null,
      'reviewed_by': null,
    });

    await setPendingTariff(branchId: branchId, tariffId: tariffId);
    return requestRef.id;
  }

  @override
  Stream<bool> watchHasPendingCashRequest() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<bool>.empty();
    }

    return _firestoreService
        .cashPaymentRequests()
        .where('student_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<_BranchInfo?> _loadBranchInfo(String branchId) async {
    final branchSnapshot =
        await _firestoreService.branches().doc(branchId).get();
    final branchData = branchSnapshot.data();
    if (branchData == null) {
      return null;
    }

    return _BranchInfo(
      branchId: branchSnapshot.id,
      branchName: branchData['name'] as String? ?? 'Sin sucursal',
      adminId: branchData['id_usuario'] as String? ?? '',
      branchColorValue: (branchData['card_color'] as num?)?.toInt(),
    );
  }

  Future<String> _resolveBranchId(String branchIdOrName) async {
    if (branchIdOrName.trim().isEmpty) return '';

    final direct = await _firestoreService.branches().doc(branchIdOrName).get();
    if (direct.exists) return direct.id;

    final query =
        await _firestoreService
            .branches()
            .where('name', isEqualTo: branchIdOrName)
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    return '';
  }

  List<_ResolvedGroup> _parseGroups(Map<String, dynamic> userData) {
    final rawGroups = userData['grupos'];
    if (rawGroups is! List) {
      final singleGroupId = userData['grupo_id']?.toString().trim() ?? '';
      if (singleGroupId.isEmpty) return const [];
      return [
        _ResolvedGroup(
          groupId: singleGroupId,
          groupName: _stringValue(
            userData['grupo_nombre'],
            fallback: singleGroupId,
          ),
          branchIdOrName: _stringValue(
            userData['grupo_sucursal'],
            fallback: '',
          ),
          beltType: _stringValue(userData['grupo_cinta'], fallback: ''),
          schedule: _stringValue(userData['grupo_horario'], fallback: ''),
          role: 'alumno',
        ),
      ];
    }

    return rawGroups
        .whereType<Map>()
        .map((rawGroup) {
          final group = Map<String, dynamic>.from(rawGroup);
          final groupId = group['groupId']?.toString().trim() ?? '';
          if (groupId.isEmpty) return null;
          return _ResolvedGroup(
            groupId: groupId,
            groupName: _stringValue(group['groupName'], fallback: groupId),
            branchIdOrName: _stringValue(
              group['branchId'],
              fallback: _stringValue(group['branchName'], fallback: ''),
            ),
            beltType: _stringValue(group['beltType'], fallback: ''),
            schedule: _stringValue(group['schedule'], fallback: ''),
            role: _stringValue(group['rol_en_grupo'], fallback: 'alumno'),
          );
        })
        .whereType<_ResolvedGroup>()
        .toList();
  }

  List<_ResolvedBranchCandidate> _parseBranchCandidates(
    Map<String, dynamic> userData,
    List<_ResolvedGroup> groups,
  ) {
    final rawBranches = userData['sucursales'];
    final tokens = <String>{};

    if (rawBranches is List) {
      for (final rawBranch in rawBranches) {
        final value = rawBranch?.toString().trim() ?? '';
        if (value.isNotEmpty) tokens.add(value);
      }
    }

    for (final group in groups) {
      if (group.branchIdOrName.trim().isNotEmpty) {
        tokens.add(group.branchIdOrName.trim());
      }
    }

    return tokens
        .map((token) => _ResolvedBranchCandidate(rawBranchToken: token))
        .toList();
  }

  List<_ResolvedGroup> _groupsForBranch(
    List<_ResolvedGroup> groups,
    String branchId,
    String branchName,
    String rawBranchToken,
  ) {
    return groups.where((group) {
      return _matchesBranch(
        group.branchIdOrName,
        branchId,
        branchName,
        rawBranchToken,
      );
    }).toList();
  }

  Map<String, _WalletPreference> _parsePreferences(
    Map<String, dynamic> userData,
  ) {
    final rawPrefs = userData['wallet_preferences'];
    if (rawPrefs is! List) {
      return <String, _WalletPreference>{};
    }

    final prefs = <String, _WalletPreference>{};
    for (final rawPref in rawPrefs) {
      if (rawPref is! Map) continue;
      final pref = _WalletPreference.fromMap(
        Map<String, dynamic>.from(rawPref),
      );
      prefs[pref.branchId] = pref;
    }
    return prefs;
  }

  Future<List<_CashRequestPreview>> _loadPendingRequests(String uid) async {
    final snapshot =
        await _firestoreService
            .cashPaymentRequests()
            .where('student_id', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();

    return snapshot.docs
        .map(
          (doc) => _CashRequestPreview(
            id: doc.id,
            branchId: doc.data()['branch_id'] as String? ?? '',
          ),
        )
        .toList();
  }

  _ResolvedGroup? _resolveGroupById(
    Map<String, dynamic> userData,
    String groupId,
  ) {
    final groups = _parseGroups(userData);
    for (final group in groups) {
      if (group.groupId == groupId) {
        return group;
      }
    }
    return null;
  }

  _ResolvedGroup _resolvePrimaryGroup(
    Map<String, dynamic> userData,
    String branchId,
  ) {
    final groups = _parseGroups(userData);
    final byBranch =
        groups.where((group) => group.branchIdOrName == branchId).toList();
    if (byBranch.isNotEmpty) return byBranch.first;
    if (groups.isNotEmpty) return groups.first;
    return _ResolvedGroup(
      groupId: '',
      groupName: 'Sin grupo',
      branchIdOrName: branchId,
      beltType: '',
      schedule: '',
      role: 'alumno',
    );
  }

  bool _matchesBranch(
    String groupBranchValue,
    String branchId,
    String branchName,
    String rawBranchToken,
  ) {
    final normalizedGroup = groupBranchValue.trim().toLowerCase();
    final normalizedId = branchId.trim().toLowerCase();
    final normalizedName = branchName.trim().toLowerCase();
    final normalizedToken = rawBranchToken.trim().toLowerCase();
    return normalizedGroup == normalizedId ||
        normalizedGroup == normalizedName ||
        normalizedGroup == normalizedToken;
  }

  String _studentFullName(Map<String, dynamic> userData) {
    final name = _stringValue(userData['nombre'], fallback: '');
    final ap = _stringValue(userData['ap'], fallback: '');
    final am = _stringValue(userData['am'], fallback: '');
    return '$name $ap $am'.trim();
  }

  String _stringValue(Object? value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty ? text : fallback;
  }
}

class _BranchInfo {
  const _BranchInfo({
    required this.branchId,
    required this.branchName,
    required this.adminId,
    required this.branchColorValue,
  });

  final String branchId;
  final String branchName;
  final String adminId;
  final int? branchColorValue;
}

class _ResolvedBranchCandidate {
  const _ResolvedBranchCandidate({required this.rawBranchToken});

  final String rawBranchToken;
}

class _ResolvedGroup {
  const _ResolvedGroup({
    required this.groupId,
    required this.groupName,
    required this.branchIdOrName,
    required this.beltType,
    required this.schedule,
    required this.role,
    this.periodType = 'month',
    this.periodCount = 1,
  });

  final String groupId;
  final String groupName;
  final String branchIdOrName;
  final String beltType;
  final String schedule;
  final String role;
  final String periodType;
  final int periodCount;

  StudentWalletGroupMembership toMembership() {
    return StudentWalletGroupMembership(
      groupId: groupId,
      groupName: groupName,
      beltType: beltType,
      schedule: schedule,
      role: role,
    );
  }

  _ResolvedGroup copyWith({String? branchId}) {
    return _ResolvedGroup(
      groupId: groupId,
      groupName: groupName,
      branchIdOrName: branchId ?? branchIdOrName,
      beltType: beltType,
      schedule: schedule,
      role: role,
      periodType: periodType,
      periodCount: periodCount,
    );
  }
}

class _WalletPreference {
  const _WalletPreference({
    required this.branchId,
    required this.branchName,
    required this.updatedAt,
    this.currentTariffId,
    this.currentTariffName,
    this.currentTariffAmountCents,
    this.currentTariffPeriodType,
    this.currentTariffPeriodCount,
    this.pendingTariffId,
    this.pendingTariffName,
    this.pendingTariffAmountCents,
    this.pendingTariffPeriodType,
    this.pendingTariffPeriodCount,
  });

  final String branchId;
  final String branchName;
  final DateTime updatedAt;
  final String? currentTariffId;
  final String? currentTariffName;
  final int? currentTariffAmountCents;
  final String? currentTariffPeriodType;
  final int? currentTariffPeriodCount;
  final String? pendingTariffId;
  final String? pendingTariffName;
  final int? pendingTariffAmountCents;
  final String? pendingTariffPeriodType;
  final int? pendingTariffPeriodCount;

  factory _WalletPreference.fromMap(Map<String, dynamic> map) {
    return _WalletPreference(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      currentTariffId: map['currentTariffId']?.toString(),
      currentTariffName: map['currentTariffName']?.toString(),
      currentTariffAmountCents:
          (map['currentTariffAmountCents'] as num?)?.toInt(),
      currentTariffPeriodType: map['currentTariffPeriodType']?.toString(),
      currentTariffPeriodCount:
          (map['currentTariffPeriodCount'] as num?)?.toInt(),
      pendingTariffId: map['pendingTariffId']?.toString(),
      pendingTariffName: map['pendingTariffName']?.toString(),
      pendingTariffAmountCents:
          (map['pendingTariffAmountCents'] as num?)?.toInt(),
      pendingTariffPeriodType: map['pendingTariffPeriodType']?.toString(),
      pendingTariffPeriodCount:
          (map['pendingTariffPeriodCount'] as num?)?.toInt(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'currentTariffId': currentTariffId,
      'currentTariffName': currentTariffName,
      'currentTariffAmountCents': currentTariffAmountCents,
      'currentTariffPeriodType': currentTariffPeriodType,
      'currentTariffPeriodCount': currentTariffPeriodCount,
      'pendingTariffId': pendingTariffId,
      'pendingTariffName': pendingTariffName,
      'pendingTariffAmountCents': pendingTariffAmountCents,
      'pendingTariffPeriodType': pendingTariffPeriodType,
      'pendingTariffPeriodCount': pendingTariffPeriodCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  _WalletPreference copyWith({
    String? branchName,
    String? currentTariffId,
    String? currentTariffName,
    int? currentTariffAmountCents,
    String? currentTariffPeriodType,
    int? currentTariffPeriodCount,
    String? pendingTariffId,
    String? pendingTariffName,
    int? pendingTariffAmountCents,
    String? pendingTariffPeriodType,
    int? pendingTariffPeriodCount,
    DateTime? updatedAt,
  }) {
    return _WalletPreference(
      branchId: branchId,
      branchName: branchName ?? this.branchName,
      currentTariffId: currentTariffId ?? this.currentTariffId,
      currentTariffName: currentTariffName ?? this.currentTariffName,
      currentTariffAmountCents:
          currentTariffAmountCents ?? this.currentTariffAmountCents,
      currentTariffPeriodType:
          currentTariffPeriodType ?? this.currentTariffPeriodType,
      currentTariffPeriodCount:
          currentTariffPeriodCount ?? this.currentTariffPeriodCount,
      pendingTariffId: pendingTariffId ?? this.pendingTariffId,
      pendingTariffName: pendingTariffName ?? this.pendingTariffName,
      pendingTariffAmountCents:
          pendingTariffAmountCents ?? this.pendingTariffAmountCents,
      pendingTariffPeriodType:
          pendingTariffPeriodType ?? this.pendingTariffPeriodType,
      pendingTariffPeriodCount:
          pendingTariffPeriodCount ?? this.pendingTariffPeriodCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class _CashRequestPreview {
  const _CashRequestPreview({required this.id, required this.branchId});

  final String id;
  final String branchId;
}
