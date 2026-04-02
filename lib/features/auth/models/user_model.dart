import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_plan/core/utils/firestore_utils.dart';

/// Firestore document model for /users/{uid}
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final DateTime createdAt;
  final int streakCount;
  final DateTime? lastActiveDate;
  final bool notificationsEnabled;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.createdAt,
    this.streakCount = 0,
    this.lastActiveDate,
    this.notificationsEnabled = true,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid:                  doc.id,
      email:                data['email']        as String? ?? '',
      displayName:          data['displayName']  as String? ?? '',
      photoURL:             data['photoURL']     as String? ?? '',
      createdAt:            FirestoreUtils.parseDateTime(data['createdAt']),
      streakCount:          data['streakCount']  as int?    ?? 0,
      lastActiveDate:       FirestoreUtils.tryParseDateTime(data['lastActiveDate']),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid':                  uid,
    'email':                email,
    'displayName':          displayName,
    'photoURL':             photoURL,
    'createdAt':            Timestamp.fromDate(createdAt),
    'streakCount':          streakCount,
    'lastActiveDate':       lastActiveDate != null
                              ? Timestamp.fromDate(lastActiveDate!)
                              : null,
    'notificationsEnabled': notificationsEnabled,
  };

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    int? streakCount,
    DateTime? lastActiveDate,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      uid:                  uid,
      email:                email,
      displayName:          displayName          ?? this.displayName,
      photoURL:             photoURL             ?? this.photoURL,
      createdAt:            createdAt,
      streakCount:          streakCount          ?? this.streakCount,
      lastActiveDate:       lastActiveDate       ?? this.lastActiveDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
