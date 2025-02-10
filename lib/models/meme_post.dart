import 'package:flutter_auth/services/meme_service.dart';

class MemePost {
  final String id;
  final String userId;
  final String userName;
  final String memeUrl;
  final String caption;
  final String? songUrl;
  final String? songTitle;
  final String? artistName;
  final DateTime createdAt;
  final List<String> likedByUsers;
  final List<String> passedByUsers;
  final String? userProfileImage; // Add this field

  MemePost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.memeUrl,
    required this.caption,
    this.songUrl,
    this.songTitle,
    this.artistName,
    required this.createdAt,
    List<String>? likedByUsers,
    List<String>? passedByUsers,
    this.userProfileImage, // Add this parameter
  })  : likedByUsers = likedByUsers ?? [],
        passedByUsers = passedByUsers ?? [];

  bool isLikedBy(String userId) => likedByUsers.contains(userId);
  bool isPassedBy(String userId) => passedByUsers.contains(userId);
  Future<bool> canChatWith(String userId) async =>
      likedByUsers.contains(userId) &&
      await UserMemeInteractions().hasUserLikedMyMeme(this.userId, userId);
}
