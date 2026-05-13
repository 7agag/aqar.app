import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String firstName;
  final String secondName;
  final String email;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.secondName,
    required this.email,
  });

  String get fullName => '$firstName $secondName';

  @override
  List<Object?> get props => [id, email];
}