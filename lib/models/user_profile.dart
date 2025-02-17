class UserProfile {
  final String userId;
  final String name;
  final int age;
  final String gender;
  final String preferredGender;
  final List<String> moodBoard;
  final String? audiusTrackId;
  final String? trackTitle;
  final String? artistName;
  final bool hasLikedMe;
  final bool canMessage;
  final String? profileImage;
  final String? bio;
  final Map<String, dynamic>? artwork;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.preferredGender,
    required this.moodBoard,
    this.audiusTrackId,
    this.trackTitle,
    this.artistName,
    required this.hasLikedMe,
    required this.canMessage,
    this.profileImage,
    this.bio,
    this.artwork,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? '',
      preferredGender: map['preferredGender'] as String? ?? '',
      moodBoard: List<String>.from(map['moodBoardImages'] ?? []),
      audiusTrackId: map['audiusTrackId'] as String?,
      trackTitle: map['trackTitle'] as String?,
      artistName: map['artistName'] as String?,
      hasLikedMe: map['hasLikedMe'] as bool? ?? false,
      canMessage: map['canMessage'] as bool? ?? false,
      profileImage: map['profileImage'] as String?,
      bio: map['bio'] as String?,
      artwork: map['artwork'] as Map<String, dynamic>?,
    );
  }

  get interests => null;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'preferredGender': preferredGender,
      'moodBoardImages': moodBoard,
      'audiusTrackId': audiusTrackId,
      'trackTitle': trackTitle,
      'artistName': artistName,
      'hasLikedMe': hasLikedMe,
      'canMessage': canMessage,
      'profileImage': profileImage,
      'bio': bio,
    };
  }
}
