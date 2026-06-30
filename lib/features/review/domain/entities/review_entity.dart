import 'package:equatable/equatable.dart';
import 'package:aqar/core/utils/parse_utils.dart';

class ReviewEntity extends Equatable {
  final String reviewId;
  final int? propertyId;
  final String? rentId;
  final double rating;
  final String phrase;
  final DateTime createdAt;
  final String? firstName;
  final String? secondName;
  final String? email;

  const ReviewEntity({
    required this.reviewId,
    this.propertyId,
    this.rentId,
    required this.rating,
    this.phrase = '',
    required this.createdAt,
    this.firstName,
    this.secondName,
    this.email,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> json) {
    return ReviewEntity(
      reviewId: (json['review_id'] as int?)?.toString() ?? '',
      propertyId: json['property_id'] as int?,
      rentId: json['rent_id']?.toString(),
      rating: parseDouble(json['rating']),
      phrase: (json['phrase'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      firstName: json['first_name'] as String?,
      secondName: json['second_name'] as String?,
      email: json['email'] as String?,
    );
  }

  String get reviewerName {
    if (firstName != null && secondName != null) {
      return '$firstName $secondName';
    }
    return firstName ?? email ?? 'Anonymous';
  }

  @override
  List<Object?> get props => [
    reviewId, propertyId, rentId, rating, phrase, createdAt,
    firstName, secondName, email,
  ];
}
