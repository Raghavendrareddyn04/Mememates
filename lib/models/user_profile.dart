class UserProfile {
  final String userId;
  final String name;
  final int age;
  final List<String> moodBoard;
  final String anthem;
  final String artistName;
  final String songTitle;
  final bool hasLikedMe;
  final String? profileImage;
  bool canMessage;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.moodBoard,
    required this.anthem,
    required this.artistName,
    required this.songTitle,
    required this.hasLikedMe,
    required this.canMessage,
    this.profileImage,
  });
}