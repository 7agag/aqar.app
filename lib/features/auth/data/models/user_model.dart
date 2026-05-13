import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.secondName,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? json['user_id'] ?? '',
        firstName: json['firstName'] ?? json['first_name'] ?? '',
        secondName: json['secondName'] ?? json['second_name'] ?? '',
        email: json['email'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'first_name': firstName,
        'second_name': secondName,
        'email': email,
      };
}