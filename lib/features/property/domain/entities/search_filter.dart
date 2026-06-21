class SearchFilter {
  final bool isBuy;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final String? rentalDuration;
  final double? minSize;
  final double? maxSize;

  const SearchFilter({
    required this.isBuy,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.rentalDuration,
    this.minSize,
    this.maxSize,
  });
}
