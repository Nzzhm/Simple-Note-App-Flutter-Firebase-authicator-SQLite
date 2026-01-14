import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final _db = FirebaseFirestore.instance;

  Future<void> upsertUser({required String uid, required String? email}) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertDeadline({
    required String uid,
    required String noteId,
    required String title,
    required DateTime? deadline,
  }) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('deadlines')
        .doc(noteId);

    if (deadline == null) {
      await ref.delete(); // kalau deadline dihapus, hapus dokumen monitoring
      return;
    }

    await ref.set({
      'title': title,
      'deadline': Timestamp.fromDate(deadline),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> readUpcomingDeadlines({
    required String uid,
    required DateTime from,
  }) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('deadlines')
        .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('deadline')
        .limit(20)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }
}
