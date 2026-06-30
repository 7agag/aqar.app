class PropertyFilterParams {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final double? minSize;
  final double? maxSize;
  final int? bedrooms;
  final int? bathrooms;
  final double? latitude;
  final double? longitude;
  final bool? featured;
  final String? listingType;
  final String? rentalDuration;

  const PropertyFilterParams({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.bedrooms,
    this.bathrooms,
    this.latitude,
    this.longitude,
    this.featured,
    this.listingType,
    this.rentalDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minSize': minSize,
      'maxSize': maxSize,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'latitude': latitude,
      'longitude': longitude,
      if (featured == true) 'featured': 'true',
      'listingType': listingType,
      'rentalDuration': rentalDuration,
    }..removeWhere((key, value) => value == null);
  }

  PropertyFilterParams copyWith({
    String? location,
    double? minPrice,
    double? maxPrice,
    double? minSize,
    double? maxSize,
    int? bedrooms,
    int? bathrooms,
    double? latitude,
    double? longitude,
    bool? featured,
    String? listingType,
    String? rentalDuration,
  }) {
    return PropertyFilterParams(
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      featured: featured ?? this.featured,
      listingType: listingType ?? this.listingType,
      rentalDuration: rentalDuration ?? this.rentalDuration,
    );
  }
}