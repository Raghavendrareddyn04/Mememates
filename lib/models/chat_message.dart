import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  meme,
  song,
}

class ChatMessage {
  final String? id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final List<String> readBy;
  final DateTime expiresAt;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    List<String>? readBy,
    DateTime? expiresAt,
  })  : readBy = readBy ?? [],
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 1));

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values[data['type'] ?? 0],
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
      'isRead': isRead,
      'readBy': readBy,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
