import 'package:cloud_firestore/cloud_firestore.dart';

class Connection {
  final String id;
  final String userId;
  final String userName;
  final String? profileImage;
  final DateTime connectedAt;

  Connection({
    required this.id,
    required this.userId,
    required this.userName,
    this.profileImage,
    required this.connectedAt,
  });

  factory Connection.fromMap(Map<String, dynamic> map, String id) {
    return Connection(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      profileImage: map['profileImage'],
      connectedAt: (map['connectedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'profileImage': profileImage,
      'connectedAt': connectedAt,
    };
  }
}
