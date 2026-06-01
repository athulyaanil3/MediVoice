import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medicine.dart';

class MedicineService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String uid =
      FirebaseAuth.instance.currentUser!.uid;

  // ADD MEDICINE
  Future<void> addMedicine(
      Medicine medicine) async {

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medicine.id)
        .set(medicine.toFirestoreMap());
  }

  // FETCH MEDICINES
  Stream<List<Medicine>> getMedicines() {

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {

      return snapshot.docs.map((doc) {

        return Medicine.fromMap(doc.data());

      }).toList();
    });
  }

  // DELETE
  Future<void> deleteMedicine(
      String medicineId) async {

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicines')
        .doc(medicineId)
        .delete();
  }
}