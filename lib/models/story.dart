import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryType {
  image,
  video,
  text,
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String content;
  final StoryType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final Map<String, dynamic>? metadata;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    List<String>? viewedBy,
    this.metadata,
  }) : viewedBy = viewedBy ?? [];

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileImage: data['userProfileImage'],
      content: data['content'] ?? '',
      type: StoryType.values[data['type'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'content': content,
      'type': type.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
      'metadata': metadata,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
