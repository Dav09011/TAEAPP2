import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tae_app/core/errors/app_exception.dart';
import 'package:tae_app/core/services/auth_service.dart';
import 'package:tae_app/core/services/firestore_service.dart';
import 'package:tae_app/features/admin/domain/entities/admin_cash_payment_request.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_branch_summary.dart';
import 'package:tae_app/features/admin/domain/entities/admin_wallet_student_status.dart';
import 'package:tae_app/features/admin/domain/repositories/admin_wallet_repository.dart';
import 'package:tae_app/features/payments/domain/entities/payment_charge.dart';
import 'package:tae_app/features/payments/domain/entities/payment_tariff.dart';

class FirebaseAdminWalletRepository implements AdminWalletRepository {
  FirebaseAdminWalletRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService(),
       _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;

  FirebaseFirestore get _db => _firestoreService.instance;

  @override
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  Future<String> getCurrentAdminFirstName() async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final snapshot = await _firestoreService.users().doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw const AppException('No se encontro el perfil del administrador.');
    }

    return data['nombre'] as String? ?? 'Usuario';
  }

  @override
  Stream<List<AdminWalletBranchSummary>> watchBranchSummaries() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<List<AdminWalletBranchSummary>>.empty();
    }

    late final StreamController<List<AdminWalletBranchSummary>> controller;
    StreamSubscription<dynamic>? branchesSubscription;
    StreamSubscription<dynamic>? chargesSubscription;
    StreamSubscription<dynamic>? requestsSubscription;
    var isRefreshing = false;
    var refreshAgain = false;

    Future<void> refresh() async {
      if (isRefreshing) {
        refreshAgain = true;
        return;
      }

      isRefreshing = true;
      try {
        final summaries = await _loadBranchSummaries(uid);
        if (!controller.isClosed) {
          controller.add(summaries);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isRefreshing = false;
        if (refreshAgain && !controller.isClosed) {
          refreshAgain = false;
          unawaited(refresh());
        }
      }
    }

    controller = StreamController<List<AdminWalletBranchSummary>>(
      onListen: () {
        branchesSubscription = _firestoreService
            .branches()
            .where('id_usuario', isEqualTo: uid)
            .orderBy('name')
            .snapshots()
            .listen((_) => unawaited(refresh()), onError: controller.addError);
        chargesSubscription = _firestoreService
            .adminPaymentCharges(uid)
            .snapshots()
            .listen((_) => unawaited(refresh()), onError: controller.addError);
        requestsSubscription = _firestoreService
            .cashPaymentRequests()
            .where('admin_id', isEqualTo: uid)
            .snapshots()
            .listen((_) => unawaited(refresh()), onError: controller.addError);
        unawaited(refresh());
      },
      onCancel: () async {
        await branchesSubscription?.cancel();
        await chargesSubscription?.cancel();
        await requestsSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<AdminWalletBranchSummary>> _loadBranchSummaries(
    String uid,
  ) async {
    final branchesSnapshot =
        await _firestoreService
            .branches()
            .where('id_usuario', isEqualTo: uid)
            .orderBy('name')
            .get();
    final chargesSnapshot =
        await _firestoreService.adminPaymentCharges(uid).get();
    final requestsSnapshot =
        await _firestoreService
            .cashPaymentRequests()
            .where('admin_id', isEqualTo: uid)
            .get();

    final summaries = <AdminWalletBranchSummary>[];
    for (final branchDoc in branchesSnapshot.docs) {
      final branchData = branchDoc.data();
      final branchId = branchDoc.id;
      final branchName = branchData['name'] as String? ?? 'Sin nombre';
      final groupsSnapshot =
          await _db
              .collection('grupos')
              .where('id_sucursal', isEqualTo: branchId)
              .get();
      var studentsCount = 0;
      for (final groupDoc in groupsSnapshot.docs) {
        final studentsSnapshot =
            await groupDoc.reference.collection('alumnos').get();
        studentsCount += studentsSnapshot.docs.length;
      }

      final paidCharges =
          chargesSnapshot.docs.where((doc) {
            final data = doc.data();
            return data['branch_id']?.toString() == branchId &&
                data['status']?.toString() == 'paid';
          }).toList();
      final pendingCharges =
          chargesSnapshot.docs.where((doc) {
            final data = doc.data();
            return data['branch_id']?.toString() == branchId &&
                data['status']?.toString() == 'pending';
          }).toList();

      summaries.add(
        AdminWalletBranchSummary(
          branchId: branchId,
          branchName: branchName,
          groupsCount: groupsSnapshot.docs.length,
          studentsCount: studentsCount,
          paidCount: paidCharges.length,
          pendingCount: pendingCharges.length,
          totalPaidCents: paidCharges.fold<int>(
            0,
            (total, doc) =>
                total +
                ((doc.data()['total_amount_cents'] as num?)?.toInt() ?? 0),
          ),
          totalPendingCents: pendingCharges.fold<int>(
            0,
            (total, doc) =>
                total +
                ((doc.data()['total_amount_cents'] as num?)?.toInt() ?? 0),
          ),
          cashRequestsCount:
              requestsSnapshot.docs.where((doc) {
                final data = doc.data();
                return data['branch_id']?.toString() == branchId &&
                    data['status']?.toString() == 'pending';
              }).length,
        ),
      );
    }
    return summaries;
  }

  @override
  Stream<List<PaymentTariff>> watchTariffs() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<List<PaymentTariff>>.empty();
    }

    return _firestoreService
        .adminPaymentTariffs(uid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PaymentTariff.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  @override
  Stream<List<AdminCashPaymentRequest>> watchCashRequests() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<List<AdminCashPaymentRequest>>.empty();
    }

    return _firestoreService
        .cashPaymentRequests()
        .where('admin_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        AdminCashPaymentRequest.fromMap(doc.id, doc.data()),
                  )
                  .toList(),
        );
  }

  @override
  Future<List<AdminWalletStudentStatus>> loadStudentStatuses({
    String? branchId,
    String? groupId,
  }) async {
    final candidates = await _loadStudentsInternal(
      branchId: branchId,
      groupId: groupId,
    );
    final charges = await _loadChargesIndex();
    return candidates.map((student) {
      final latest = charges[student.studentId];
      final status = latest?.status ?? 'unregistered';
      final lastPaymentCents = latest?.totalAmountCents ?? 0;
      final pendingCents =
          latest == null || latest.status != 'paid'
              ? latest?.totalAmountCents ?? 0
              : 0;
      return AdminWalletStudentStatus(
        studentId: student.studentId,
        studentName: student.studentName,
        branchId: student.branchId,
        branchName: student.branchName,
        groupId: student.groupId,
        groupName: student.groupName,
        status: status,
        billingLabel:
            latest == null
                ? 'Sin cobro registrado'
                : latest.status == 'paid'
                ? 'Mensualidad pagada'
                : latest.status == 'pending'
                ? 'Mensualidad pendiente'
                : 'Cobro ${latest.status}',
        lastPaymentLabel:
            latest == null
                ? 'Sin pagos registrados'
                : 'Ultimo pago: \$${(lastPaymentCents / 100).toStringAsFixed(2)}',
        lastPaymentCents: lastPaymentCents,
        pendingCents: pendingCents,
        isScholarship: false,
      );
    }).toList();
  }

  @override
  Future<List<AdminWalletStudentStatus>> loadCashPaymentCandidates({
    String? branchId,
    String? groupId,
  }) {
    return loadStudentStatuses(branchId: branchId, groupId: groupId);
  }

  @override
  Future<String> createCashPaymentRequest({
    required String studentId,
    required String studentName,
    required String branchId,
    required String branchName,
    required String groupId,
    required String groupName,
    required int amountCents,
    String? note,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final now = DateTime.now();
    final doc = _firestoreService.cashPaymentRequests().doc();
    await doc.set({
      'admin_id': uid,
      'student_id': studentId,
      'student_name': studentName,
      'branch_id': branchId,
      'branch_name': branchName,
      'group_id': groupId,
      'group_name': groupName,
      'amount_cents': amountCents,
      'status': 'pending',
      'note': note,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'reviewed_at': null,
      'reviewed_by': null,
    });
    return doc.id;
  }

  @override
  Future<void> approveCashPaymentRequest(String requestId) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final requestRef = _firestoreService.cashPaymentRequests().doc(requestId);
    final requestSnapshot = await requestRef.get();
    if (!requestSnapshot.exists) {
      throw const AppException('La solicitud no existe.');
    }

    final data = requestSnapshot.data()!;
    final now = DateTime.now();
    final chargeDoc = _firestoreService.adminPaymentCharges(uid).doc();
    final studentId = data['student_id']?.toString() ?? '';
    final branchId = data['branch_id']?.toString() ?? '';
    final tariffId = data['tariff_id']?.toString() ?? '';
    final tariffName = data['tariff_name']?.toString() ?? 'Pago en efectivo';
    final amountCents = (data['amount_cents'] as num?)?.toInt() ?? 0;
    final periodType = data['period_type']?.toString() ?? 'month';
    final periodCount = (data['period_count'] as num?)?.toInt() ?? 1;
    await chargeDoc.set({
      'admin_id': uid,
      'student_id': studentId,
      'student_name': data['student_name'],
      'tariff_id': tariffId.isEmpty ? null : tariffId,
      'tariff_name': tariffName,
      'branch_id': branchId,
      'branch_name': data['branch_name'],
      'group_id': data['group_id'],
      'group_name': data['group_name'],
      'amount_cents': amountCents,
      'currency': 'mxn',
      'discount_amount_cents': 0,
      'total_amount_cents': amountCents,
      'provider': 'cash',
      'status': 'paid',
      'period_start': Timestamp.fromDate(now),
      'period_end': Timestamp.fromDate(now),
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'discount_code_id': null,
      'discount_code': null,
      'checkout_session_id': null,
      'checkout_url': null,
      'payment_intent_id': null,
      'invoice_id': null,
      'paid_at': Timestamp.fromDate(now),
    });

    if (studentId.isNotEmpty && branchId.isNotEmpty) {
      await _syncStudentWalletPreferenceOnApproval(
        studentId: studentId,
        branchId: branchId,
        tariffId: tariffId,
        tariffName: tariffName,
        amountCents: amountCents,
        periodType: periodType,
        periodCount: periodCount,
        groupId: data['group_id']?.toString() ?? '',
        groupName: data['group_name']?.toString() ?? '',
      );
    }

    await requestRef.update({
      'status': 'approved',
      'reviewed_at': Timestamp.fromDate(now),
      'reviewed_by': uid,
      'updated_at': Timestamp.fromDate(now),
      'charge_id': chargeDoc.id,
    });
  }

  @override
  Future<void> rejectCashPaymentRequest(String requestId) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final requestRef = _firestoreService.cashPaymentRequests().doc(requestId);

    await requestRef.update({
      'status': 'rejected',
      'reviewed_at': Timestamp.fromDate(DateTime.now()),
      'reviewed_by': uid,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> createOrUpdateTariff({
    String? tariffId,
    required String branchId,
    required String name,
    required int amountCents,
    required String currency,
    required String periodType,
    required int periodCount,
    String? groupId,
    String? description,
    bool isActive = true,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    final ref =
        tariffId == null
            ? _firestoreService.adminPaymentTariffs(uid).doc()
            : _firestoreService.adminPaymentTariffs(uid).doc(tariffId);

    await ref.set({
      'admin_id': uid,
      'branch_id': branchId,
      'group_id': groupId,
      'name': name.trim(),
      'amount_cents': amountCents,
      'currency': currency,
      'period_type': periodType,
      'period_count': periodCount,
      'description': description,
      'is_active': isActive,
      'active': isActive,
      'activa': isActive,
      'stripe_product_id': null,
      'stripe_price_id': null,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteTariff(String tariffId) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    await _firestoreService.adminPaymentTariffs(uid).doc(tariffId).delete();
  }

  Future<List<_StudentCandidate>> _loadStudentsInternal({
    String? branchId,
    String? groupId,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const AppException('No hay sesion activa.');
    }

    Query<Map<String, dynamic>> branchesQuery = _firestoreService
        .branches()
        .where('id_usuario', isEqualTo: uid);
    final branchesSnapshot = await branchesQuery.get();
    final branchDocs =
        branchesSnapshot.docs.where((doc) {
          if (branchId == null || branchId.isEmpty) return true;
          return doc.id == branchId;
        }).toList();

    final candidatesByStudentId = <String, _StudentCandidate>{};
    for (final branchDoc in branchDocs) {
      final branchName = branchDoc.data()['name'] as String? ?? 'Sin sucursal';
      final groupsSnapshot =
          await _db
              .collection('grupos')
              .where('id_sucursal', isEqualTo: branchDoc.id)
              .get();

      for (final groupDoc in groupsSnapshot.docs) {
        final groupData = groupDoc.data();
        final currentGroupId = groupDoc.id;
        if (groupId != null &&
            groupId.isNotEmpty &&
            currentGroupId != groupId) {
          continue;
        }

        final groupName = groupData['nombre_grupo'] as String? ?? 'Sin grupo';
        final studentsSnapshot =
            await groupDoc.reference.collection('alumnos').get();
        for (final studentDoc in studentsSnapshot.docs) {
          final studentData = studentDoc.data();
          final studentId =
              studentData['uid']?.toString().trim().isNotEmpty == true
                  ? studentData['uid'].toString()
                  : studentDoc.id;
          final studentName =
              studentData['nombre']?.toString().trim().isNotEmpty == true
                  ? studentData['nombre'].toString()
                  : (studentData['nombre_completo']?.toString() ??
                      'Sin nombre');
          candidatesByStudentId.putIfAbsent(
            studentId,
            () => _StudentCandidate(
              studentId: studentId,
              studentName: studentName,
              branchId: branchDoc.id,
              branchName: branchName,
              groupId: currentGroupId,
              groupName: groupName,
            ),
          );
        }
      }
    }

    return candidatesByStudentId.values.toList();
  }

  Future<Map<String, PaymentCharge>> _loadChargesIndex() async {
    final uid = currentUserId;
    if (uid == null) {
      return const {};
    }

    final snapshot =
        await _firestoreService
            .adminPaymentCharges(uid)
            .orderBy('created_at', descending: true)
            .get();
    final index = <String, PaymentCharge>{};
    for (final doc in snapshot.docs) {
      final charge = PaymentCharge.fromMap(doc.id, doc.data());
      index.putIfAbsent(charge.studentId, () => charge);
    }
    return index;
  }

  Future<void> _syncStudentWalletPreferenceOnApproval({
    required String studentId,
    required String branchId,
    required String tariffId,
    required String tariffName,
    required int amountCents,
    required String periodType,
    required int periodCount,
    required String groupId,
    required String groupName,
  }) async {
    final ref = _firestoreService.users().doc(studentId);
    final snapshot = await ref.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final preferences = _parseWalletPreferences(data);
    final existing = preferences[branchId];
    preferences[branchId] = _WalletPreference(
      branchId: branchId,
      branchName:
          existing?.branchName ?? data['grupo_sucursal']?.toString() ?? '',
      currentTariffId: tariffId,
      currentTariffName: tariffName,
      currentTariffAmountCents: amountCents,
      currentTariffPeriodType: periodType,
      currentTariffPeriodCount: periodCount,
      pendingTariffId: existing?.pendingTariffId,
      pendingTariffName: existing?.pendingTariffName,
      pendingTariffAmountCents: existing?.pendingTariffAmountCents,
      pendingTariffPeriodType: existing?.pendingTariffPeriodType,
      pendingTariffPeriodCount: existing?.pendingTariffPeriodCount,
      updatedAt: DateTime.now(),
    );

    await ref.set({
      'wallet_preferences':
          preferences.values.map((pref) => pref.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  Map<String, _WalletPreference> _parseWalletPreferences(
    Map<String, dynamic> data,
  ) {
    final raw = data['wallet_preferences'];
    if (raw is! List) return <String, _WalletPreference>{};

    final prefs = <String, _WalletPreference>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final pref = _WalletPreference.fromMap(Map<String, dynamic>.from(item));
      prefs[pref.branchId] = pref;
    }
    return prefs;
  }
}

class _StudentCandidate {
  const _StudentCandidate({
    required this.studentId,
    required this.studentName,
    required this.branchId,
    required this.branchName,
    required this.groupId,
    required this.groupName,
  });

  final String studentId;
  final String studentName;
  final String branchId;
  final String branchName;
  final String groupId;
  final String groupName;
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
