class PropertyFilterParams {
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final double? latitude;
  final double? longitude;
  final bool? featured;

  const PropertyFilterParams({
    this.location,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.latitude,
    this.longitude,
    this.featured,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'latitude': latitude,
      'longitude': longitude,
      if (featured == true) 'featured': 'true',
    }..removeWhere((key, value) => value == null);
  }

  PropertyFilterParams copyWith({
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    double? latitude,
    double? longitude,
    bool? featured,
  }) {
    return PropertyFilterParams(
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      featured: featured ?? this.featured,
    );
  }
}