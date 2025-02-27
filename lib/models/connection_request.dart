import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime timestamp;
  final String senderName;
  final String receiverName;
  final String? senderProfileImage;
  final String? receiverProfileImage;

  ConnectionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
    required this.senderName,
    required this.receiverName,
    this.senderProfileImage,
    this.receiverProfileImage,
  });

  factory ConnectionRequest.fromMap(Map<String, dynamic> map, String id) {
    return ConnectionRequest(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: map['senderName'] ?? '',
      receiverName: map['receiverName'] ?? '',
      senderProfileImage: map['senderProfileImage'],
      receiverProfileImage: map['receiverProfileImage'],
    );
  }
}
