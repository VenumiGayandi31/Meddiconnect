class MedicineModel {
  final String id;
  
  final String name;
  final String brand;
  final String location;
  final String pharmacyName;
  final String pharmacyId;
  final double price;
  final int stockCount;

  MedicineModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.location,
    required this.pharmacyName,
    required this.pharmacyId,
    required this.price,
    required this.stockCount,
  });

  factory MedicineModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return MedicineModel(
      id: docId,
      
      name: data['name'] as String? ?? 'Unknown',
      brand: data['brand'] as String? ?? 'Unknown',
      location: data['location'] as String? ?? 'Unknown',
      pharmacyName: data['pharmacyName'] as String? ?? 'Unknown',
      pharmacyId: data['pharmacyId'] as String? ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      
      stockCount: data['stockCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'location': location,
      'pharmacyName': pharmacyName,
      'pharmacyId': pharmacyId,
      'price': price,
      'stockCount': stockCount,
    };
  }
}
