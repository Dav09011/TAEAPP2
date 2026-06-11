import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCashPaymentRequest {
  const AdminCashPaymentRequest({
    required this.id,
    required this.adminId,
    required this.studentId,
    required this.studentName,
    required this.branchId,
    required this.branchName,
    required this.groupId,
    required this.groupName,
    required this.amountCents,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.periodStart,
    this.periodEnd,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String adminId;
  final String studentId;
  final String studentName;
  final String branchId;
  final String branchName;
  final String groupId;
  final String groupName;
  final int amountCents;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  factory AdminCashPaymentRequest.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AdminCashPaymentRequest(
      id: id,
      adminId: map['admin_id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      studentName: map['student_name'] as String? ?? '',
      branchId: map['branch_id'] as String? ?? '',
      branchName: map['branch_name'] as String? ?? '',
      groupId: map['group_id'] as String? ?? '',
      groupName: map['group_name'] as String? ?? '',
      amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: _readDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _readDate(map['updated_at']) ?? DateTime.now(),
      note: map['note'] as String?,
      periodStart: _readDate(map['period_start']),
      periodEnd: _readDate(map['period_end']),
      reviewedAt: _readDate(map['reviewed_at']),
      reviewedBy: map['reviewed_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'student_id': studentId,
      'student_name': studentName,
      'branch_id': branchId,
      'branch_name': branchName,
      'group_id': groupId,
      'group_name': groupName,
      'amount_cents': amountCents,
      'status': status,
      'note': note,
      'period_start': periodStart == null ? null : Timestamp.fromDate(periodStart!),
      'period_end': periodEnd == null ? null : Timestamp.fromDate(periodEnd!),
      'reviewed_at': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewed_by': reviewedBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  AdminCashPaymentRequest copyWith({
    String? id,
    String? adminId,
    String? studentId,
    String? studentName,
    String? branchId,
    String? branchName,
    String? groupId,
    String? groupName,
    int? amountCents,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return AdminCashPaymentRequest(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
