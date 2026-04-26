import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(this._uid);

  final String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    if (_uid == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists || doc.data() == null) return null;
      
      final data = doc.data()!;
      // Profile is incomplete if age is not set (onboarding not completed)
      if (data['age'] == null || data['age'] == 0) {
        return null;
      }
      return UserProfile.fromMap(_uid, data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> fetchDisplayName() async {
    if (_uid == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists || doc.data() == null) return null;
      
      return doc.data()!['displayName'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (_uid == null) throw Exception('Cannot save profile: User not logged in.');
    
    final data = profile.toMap();
    // Don't save uid in the document itself as it's the document ID
    data.remove('uid');
    
    await _firestore.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }
}
