import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  FirebaseFirestore get instance => _firestore;

  CollectionReference<Map<String, dynamic>> users() {
    return _firestore.collection('usuarios');
  }

  CollectionReference<Map<String, dynamic>> branches() {
    return _firestore.collection('sucursales');
  }

  CollectionReference<Map<String, dynamic>> adminPaymentTariffs(String adminId) {
    return users().doc(adminId).collection('tarifas');
  }

  CollectionReference<Map<String, dynamic>> adminPaymentDiscountCodes(
    String adminId,
  ) {
    return users().doc(adminId).collection('descuentos');
  }

  CollectionReference<Map<String, dynamic>> adminPaymentCharges(
    String adminId,
  ) {
    return users().doc(adminId).collection('cobros');
  }

  CollectionReference<Map<String, dynamic>> cashPaymentRequests() {
    return _firestore.collection('cash_payment_requests');
  }
}
