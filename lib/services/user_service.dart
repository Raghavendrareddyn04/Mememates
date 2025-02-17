import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

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
    String? audiusTrackId,
    String? trackTitle,
    String? artistName,
    String? profileImage,
    String? bio,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'age': age,
        'gender': gender,
        'preferredGender': preferredGender,
        'moodBoardImages': moodBoardImages,
        'audiusTrackId': audiusTrackId,
        'trackTitle': trackTitle,
        'artistName': artistName,
        'profileImage': profileImage,
        'bio': bio,
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

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserProfile(
        userId: userId,
        name: data['name'] ?? '',
        age: data['age'] ?? 0,
        moodBoard: List<String>.from(data['moodBoardImages'] ?? []),
        audiusTrackId: data['audiusTrackId'],
        trackTitle: data['trackTitle'],
        artistName: data['artistName'],
        hasLikedMe: data['hasLikedMe'] ?? false,
        canMessage: data['canMessage'] ?? false,
        profileImage: data['profileImage'],
        bio: data['bio'],
        artwork: data['artwork'] as Map<String, dynamic>?,
      );
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
    String? audiusTrackId,
    String? profileImage,
    int? age,
    String? gender,
    String? preferredGender,
    String? trackTitle,
    String? artistName,
    List<String>? interests,
  }) async {
    try {
      // Verify the document exists first
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create the document if it doesn't exist
        await docRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }
      if (bio != null) updates['bio'] = bio;
      if (moodBoardImages != null) updates['moodBoardImages'] = moodBoardImages;
      if (audiusTrackId != null) updates['audiusTrackId'] = audiusTrackId;
      if (trackTitle != null) updates['trackTitle'] = trackTitle;
      if (artistName != null) updates['artistName'] = artistName;
      if (profileImage != null) {
        updates['profileImage'] = profileImage;
        await _auth.currentUser?.updatePhotoURL(profileImage);
      }
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (preferredGender != null) updates['preferredGender'] = preferredGender;
      if (interests != null) updates['interests'] = interests;

      await docRef.update(updates);
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

  Stream<List<UserProfile>> getMatchedUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('userId', isNotEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserProfile(
          userId: doc.id,
          name: data['name'] ?? '',
          age: data['age'] ?? 0,
          moodBoard: List<String>.from(data['moodBoardImages'] ?? []),
          audiusTrackId: data['audiusTrackId'],
          trackTitle: data['trackTitle'],
          artistName: data['artistName'],
          hasLikedMe: data['hasLikedMe'] ?? false,
          canMessage: data['canMessage'] ?? false,
          profileImage: data['profileImage'],
          bio: data['bio'],
        );
      }).toList();
    });
  }
}
