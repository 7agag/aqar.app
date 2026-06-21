import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String firstName;
  final String secondName;
  final String email;
  final int propertiesCount;
  final int favoritesCount;
  final bool isOnline;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.secondName,
    required this.email,
    this.propertiesCount = 0,
    this.favoritesCount = 0,
    this.isOnline = false,
    this.isVerified = false,
  });

  String get fullName => '$firstName $secondName'.trim();

  UserEntity copyWith({
    String? firstName,
    String? secondName,
    String? email,
  }) {
    return UserEntity(
      id: id,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      email: email ?? this.email,
      propertiesCount: propertiesCount,
      favoritesCount: favoritesCount,
      isOnline: isOnline,
      isVerified: isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        secondName,
        email,
        propertiesCount,
        favoritesCount,
        isOnline,
        isVerified,
      ];
}
