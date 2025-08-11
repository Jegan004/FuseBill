import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _subscriptions = FirebaseFirestore.instance.collection('subscriptions');

  Stream<QuerySnapshot> getUserSubscriptions(String uid) {
    // Changed 'userId' to 'uid' to match your add_subscription_screen.dart
    return _subscriptions.where('uid', isEqualTo: uid).snapshots();
  }

  Future<void> addSubscription(Map<String, dynamic> data) async {
    await _subscriptions.add(data);
  }

  Future<void> deleteSubscription(String docId) async {
    await _subscriptions.doc(docId).delete();
  }
}
