import 'package:flutter_auth/services/meme_service.dart';

class MemePost {
  final String id;
  final String userId;
  final String userName;
  final String memeUrl;
  final String caption;
  final String? videoId;
  final String? videoTitle;
  final String? artistName;
  final DateTime createdAt;
  List<String> likedByUsers;
  List<String> passedByUsers;
  final String? userProfileImage;
  bool _isReverted = false;
  final _memeService = MemeService();

  MemePost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.memeUrl,
    required this.caption,
    this.videoId,
    this.videoTitle,
    this.artistName,
    required this.createdAt,
    List<String>? likedByUsers,
    List<String>? passedByUsers,
    this.userProfileImage,
  })  : likedByUsers = likedByUsers ?? [],
        passedByUsers = passedByUsers ?? [];

  bool get isReverted => _isReverted;

  String get timestamp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  bool isLikedBy(String userId) => likedByUsers.contains(userId);
  bool isPassedBy(String userId) => passedByUsers.contains(userId);

  Future<bool> canChatWith(String userId) async {
    if (this.userId == userId) return false;
    return likedByUsers.contains(userId) &&
        await _memeService.hasUserLikedMyMeme(userId, this.userId);
  }

  String getInteractionText(String currentUserId) {
    if (_isReverted) {
      return "Interaction removed";
    }
    if (userId == currentUserId) {
      return "This is your meme";
    } else if (isLikedBy(currentUserId)) {
      return "You liked this meme! 👍";
    } else if (isPassedBy(currentUserId)) {
      return "You passed on this meme ✋";
    }
    return "";
  }

  void like(String userId) {
    if (!isLikedBy(userId) && !isPassedBy(userId)) {
      likedByUsers.add(userId);
      _isReverted = false;
    }
  }

  void pass(String userId) {
    if (!isPassedBy(userId) && !isLikedBy(userId)) {
      passedByUsers.add(userId);
      _isReverted = false;
    }
  }

  void removeInteractions(String userId) {
    if (likedByUsers.remove(userId) || passedByUsers.remove(userId)) {
      _isReverted = true;
    }
  }

  bool shouldRemoveFromView(String currentUserId) {
    return !_isReverted &&
        (isLikedBy(currentUserId) || isPassedBy(currentUserId));
  }

  void resetRevertState() {
    _isReverted = false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemePost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
