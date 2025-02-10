import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required int age,
    required String gender,
    required String preferredGender,
    required List<String> moodBoardImages,
    String? anthem,
    String? artistName,
    String? songTitle,
    String? profileImage,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'age': age,
        'gender': gender,
        'preferredGender': preferredGender,
        'moodBoardImages': moodBoardImages,
        'anthem': anthem,
        'artistName': artistName,
        'songTitle': songTitle,
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'autoplayMusic': true,
          'showAge': true,
          'privateMoodBoard': false,
          'showOnlineStatus': true,
          'receiveNotifications': true,
          'minAge': 18,
          'maxAge': 35,
          'maxDistance': 50,
          'selectedCategories': ['Funny', 'Music'],
        },
      });

      // Update Auth profile
      if (profileImage != null) {
        await _auth.currentUser?.updatePhotoURL(profileImage);
      }
      await _auth.currentUser?.updateDisplayName(name);
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['settings'] as Map<String, dynamic>?;
    } catch (e) {
      throw 'Failed to get user settings: $e';
    }
  }

  Future<void> updateUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'settings': settings,
      });
    } catch (e) {
      throw 'Failed to update user settings: $e';
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    List<String>? moodBoardImages,
    String? anthem,
    String? profileImage,
    int? age,
    String? gender,
    String? preferredGender,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }
      if (bio != null) updates['bio'] = bio;
      if (moodBoardImages != null) updates['moodBoardImages'] = moodBoardImages;
      if (anthem != null) updates['anthem'] = anthem;
      if (profileImage != null) {
        updates['profileImage'] = profileImage;
        await _auth.currentUser?.updatePhotoURL(profileImage);
      }
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (preferredGender != null) updates['preferredGender'] = preferredGender;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  Future<void> deactivateAccount(String userId) async {
    try {
      // Delete user data
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user's memes
      final memesQuery = await _firestore
          .collection('memes')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in memesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await _auth.currentUser?.delete();
    } catch (e) {
      throw 'Failed to deactivate account: $e';
    }
  }
}