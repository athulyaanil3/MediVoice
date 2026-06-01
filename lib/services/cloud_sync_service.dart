import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/medicine.dart';
import 'local_store.dart';

class CloudSyncService {

  CloudSyncService._();

  static final CloudSyncService instance =
  CloudSyncService._();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final Connectivity _connectivity =
  Connectivity();


  // CHECK INTERNET


  Future<bool> _online() async {

    final result =
    await _connectivity
        .checkConnectivity();

    return result !=
        ConnectivityResult.none;
  }


  // FIRESTORE COLLECTION


  CollectionReference<Map<String, dynamic>>?
  _col() {

    final uid = FirebaseAuth
        .instance.currentUser?.uid;

    if (uid == null) return null;

    return _db
        .collection('users')
        .doc(uid)
        .collection('medicines');
  }


  // PUSH MEDICINE TO CLOUD

  Future<void> pushMedicine(
      Medicine medicine,
      ) async {

    try {

      final user =
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(medicine.id)
          .set(
        medicine.toFirestoreMap(),
        SetOptions(
          merge: true,
        ),
      );

    } catch (e) {

      debugPrint(
        'Push medicine error: $e',
      );
    }
  }


  // DELETE FROM CLOUD


  Future<void> deleteRemoteMedicine(
      String id,
      ) async {

    if (!await _online()) return;

    final col = _col();

    if (col == null) return;

    await col.doc(id).delete();
  }


  // DOWNLOAD CLOUD DATA


  Future<void> mergeFromCloud() async {

    if (!await _online()) return;

    final col = _col();

    if (col == null) return;

    final snapshot = await col.get();

    final local =
    LocalStore.readMedicines();

    final byId = {
      for (final m in local)
        m.id: m,
    };

    for (final doc in snapshot.docs) {

      final remote =
      Medicine.fromMap({
        ...doc.data(),
        'id': doc.id,
      });

      final prev = byId[remote.id];

      if (prev == null ||
          remote.createdAt.isAfter(
            prev.createdAt,
          )) {

        byId[remote.id] = remote;
      }
    }

    for (final medicine
    in byId.values) {

      await LocalStore.upsertMedicine(
        medicine,
      );
    }
  }


  // REALTIME SYNC


  Stream<void> watchMedicines() async* {

    final col = _col();

    if (col == null) return;

    await for (final snapshot
    in col.snapshots()) {

      for (final doc
      in snapshot.docs) {

        final medicine =
        Medicine.fromMap({
          ...doc.data(),
          'id': doc.id,
        });

        await LocalStore.upsertMedicine(
          medicine,
        );
      }

      yield null;
    }
  }
}