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
  final String? audiusTrackId;
  final String? trackTitle;
  final Map<String, dynamic>? artwork;
  final DateTime createdAt;
  List<String> likedByUsers;
  List<String> passedByUsers;
  List<String> temporarilyPassedUsers;
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
    this.audiusTrackId,
    this.trackTitle,
    this.artwork,
    required this.createdAt,
    List<String>? likedByUsers,
    List<String>? passedByUsers,
    List<String>? temporarilyPassedUsers,
    this.userProfileImage,
  })  : likedByUsers = likedByUsers ?? [],
        passedByUsers = passedByUsers ?? [],
        temporarilyPassedUsers = temporarilyPassedUsers ?? [];

  bool get isReverted => _isReverted;

  // Add a getter to determine if the meme is a video
  bool get isVideo => memeUrl.toLowerCase().endsWith('.mp4');

  bool isTemporarilyPassed(String userId) =>
      temporarilyPassedUsers.contains(userId);

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
    } else if (isPassedBy(currentUserId) &&
        !isTemporarilyPassed(currentUserId)) {
      return "You passed on this meme ✋";
    }
    return "";
  }

  void like(String userId) {
    if (!isLikedBy(userId) && !isPassedBy(userId)) {
      likedByUsers.add(userId);
      temporarilyPassedUsers.remove(userId);
      _isReverted = false;
    }
  }

  void pass(String userId) {
    if (!isPassedBy(userId) && !isLikedBy(userId)) {
      passedByUsers.add(userId);
      temporarilyPassedUsers.remove(userId);
      _isReverted = false;
    }
  }

  void temporaryPass(String userId) {
    if (!isPassedBy(userId) && !isLikedBy(userId)) {
      temporarilyPassedUsers.add(userId);
      passedByUsers.remove(userId);
    }
  }

  void removeInteractions(String userId) {
    likedByUsers.remove(userId);
    passedByUsers.remove(userId);
    temporarilyPassedUsers.remove(userId);
    _isReverted = true;
  }

  bool shouldRemoveFromView(String currentUserId) {
    return !_isReverted &&
        (isLikedBy(currentUserId) ||
            (isPassedBy(currentUserId) && !isTemporarilyPassed(currentUserId)));
  }

  void resetRevertState() {
    _isReverted = false;
  }

  factory MemePost.fromMap(Map<String, dynamic> map) {
    return MemePost(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      memeUrl: map['memeUrl'] ?? '',
      caption: map['caption'] ?? '',
      videoId: map['videoId'],
      videoTitle: map['videoTitle'],
      artistName: map['artistName'],
      audiusTrackId: map['audiusTrackId'],
      trackTitle: map['trackTitle'],
      artwork: map['artwork'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      likedByUsers: List<String>.from(map['likedByUsers'] ?? []),
      passedByUsers: List<String>.from(map['passedByUsers'] ?? []),
      temporarilyPassedUsers:
          List<String>.from(map['temporarilyPassedUsers'] ?? []),
      userProfileImage: map['userProfileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'memeUrl': memeUrl,
      'caption': caption,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'artistName': artistName,
      'audiusTrackId': audiusTrackId,
      'trackTitle': trackTitle,
      'artwork': artwork,
      'createdAt': createdAt,
      'likedByUsers': likedByUsers,
      'passedByUsers': passedByUsers,
      'temporarilyPassedUsers': temporarilyPassedUsers,
      'userProfileImage': userProfileImage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemePost && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  get trackArtwork => null;
}
