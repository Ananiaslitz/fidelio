class Merchant {
  final String id;
  final String name;
  final String? address;
  final String? logoUrl;
  final String? bannerUrl;
  final double distanceKm;
  final int campaignCount;
  final String? category; // Added category

  Merchant({
    required this.id,
    required this.name,
    this.address,
    this.logoUrl,
    this.bannerUrl,
    required this.distanceKm,
    required this.campaignCount,
    this.category,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      // Handle numeric types safely from JSON
      distanceKm: (json['distance_km'] as num).toDouble(),
      campaignCount: (json['campaign_count'] as num).toInt(),
      category: json['category'],
    );
  }
}
