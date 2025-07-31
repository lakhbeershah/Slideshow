import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in the application
enum UserRole { owner, customer }

/// User model representing a user in the system
/// Can be either a shop owner or a customer
class UserModel {
  final String id;
  final String phoneNumber;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a UserModel from a Map (typically from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      role: _roleFromString(map['role'] ?? ''),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts UserModel to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Creates a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to convert string to UserRole enum
  static UserRole _roleFromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.customer; // Default to customer
    }
  }

  /// Check if user is a shop owner
  bool get isOwner => role == UserRole.owner;

  /// Check if user is a customer
  bool get isCustomer => role == UserRole.customer;

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        phoneNumber.hashCode ^
        name.hashCode ^
        role.hashCode;
  }
}