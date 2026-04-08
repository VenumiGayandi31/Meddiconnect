class OrderModel {
  final String id;
  final String userId; // patient uid
  final String userName;
  final String userPhone;
  final String email;
  final String userAddress;
  final String town;
  final String postalCode;
  final String pharmacistUid;
  final String pharmacyName;
  final double totalPrice;
  final List<dynamic> items;
  final DateTime? timestamp;
  final String status;
  final String? prescriptionUrl;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.email,
    required this.userAddress,
    required this.town,
    required this.postalCode,
    required this.pharmacistUid,
    required this.pharmacyName,
    required this.totalPrice,
    required this.items,
    this.status = 'approved',
    this.timestamp,
    this.prescriptionUrl,
  });

  
  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? data['phone'] ?? '',
      email: data['email'] ?? '',
      userAddress: data['userAddress'] ?? data['address'] ?? '',
      town: data['town'] ?? '',
      postalCode: data['postalCode'] ?? '',
      pharmacistUid: data['pharmacistUid'] ?? data['pharmacyId'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      totalPrice: (data['totalPrice'] ?? data['totalAmount'] ?? 0).toDouble(),
      items: data['items'] ?? [],
      status: data['status'] ?? 'approved',
      timestamp: data['timestamp'] != null ? DateTime.parse(data['timestamp']) : (data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null),
      prescriptionUrl: data['prescriptionUrl'],
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'email': email,
      'userAddress': userAddress,
      'town': town,
      'postalCode': postalCode,
      'pharmacistUid': pharmacistUid,
      'pharmacyName': pharmacyName,
      'totalPrice': totalPrice,
      'items': items,
      'status': status,
      'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'prescriptionUrl': prescriptionUrl,
    };
  }
}
