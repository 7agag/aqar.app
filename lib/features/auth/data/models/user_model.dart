import 'dart:convert';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.secondName,
    required super.email,
    super.propertiesCount,
    super.favoritesCount,
    super.isOnline,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['user_id'] ?? '',
        firstName: json['firstName'] ?? json['first_name'] ?? '',
        secondName: json['secondName'] ?? json['second_name'] ?? '',
        email: json['email'] ?? '',
        propertiesCount: _parseCount(json['properties']),
        favoritesCount: _parseCount(json['favorites']),
        isOnline: _parseBool(json['isOnline'] ?? json['is_online']),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'first_name': firstName,
        'second_name': secondName,
        'email': email,
        'properties': propertiesCount,
        'favorites': favoritesCount,
        'is_online': isOnline,
        'is_verified': isVerified,
      };

  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is List) return value.length;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      final parsedNumber = int.tryParse(trimmed);
      if (parsedNumber != null) return parsedNumber;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) return decoded.length;
        if (decoded is num) return decoded.toInt();
      } on FormatException {
        return 0;
      }
    }
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
