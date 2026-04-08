import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';

class DatabaseService {
  // Using the plural 'medicines' reference
  final CollectionReference _medicinesCollection =
      FirebaseFirestore.instance.collection('medicines');
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Add Medicine (Create)
  Future<void> addMedicine(MedicineModel medicine) async {
    try {
      await _medicinesCollection.doc(medicine.id).set(medicine.toJson());
    } catch (e) {
      print('Error adding medicine: $e');
      rethrow;
    }
  }

  // Get Medicines (Read)
  Stream<List<MedicineModel>> getMedicines() {
    return _medicinesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        return MedicineModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  // Update Stock (Update)
  Future<void> updateStock(String id, int newStockCount) async {
    try {
      await _medicinesCollection.doc(id).update({
        'stockCount': newStockCount,
      });
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  // Delete Medicine (Delete)
  Future<void> deleteMedicine(String id) async {
    try {
      await _medicinesCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting medicine: $e');
      rethrow;
    }
  }

  // Place Order (Create)
  Future<void> placeOrder(OrderModel order) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final orderRef = _ordersCollection.doc();
      final orderId = orderRef.id;

      final orderMap = order.toMap();
      // Normalize status for the app (pharmacist UI expects "Pending" initially)
      orderMap['status'] = 'Pending';
      orderMap['createdAt'] = FieldValue.serverTimestamp();
      orderMap['orderId'] = orderId;

      final patientOrderRef = _usersCollection
          .doc(order.userId)
          .collection('orders')
          .doc(orderId);
      final pharmacistOrderRef = _usersCollection
          .doc(order.pharmacistUid)
          .collection('orders')
          .doc(orderId);

      final batch = firestore.batch();
      batch.set(orderRef, orderMap);
      batch.set(patientOrderRef, orderMap);
      batch.set(pharmacistOrderRef, orderMap);
      await batch.commit();
    } catch (e) {
      print('Error placing order: $e');
      rethrow;
    }
  }

  // Get Orders for a specific user (patient)
  Stream<List<OrderModel>> getOrdersForUser(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Get Orders for a specific pharmacist (by pharmacistUid)
  Stream<List<OrderModel>> getOrdersForPharmacist(String pharmacistUid) {
    return _usersCollection
        .doc(pharmacistUid)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Update Order Status
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    required String patientUid,
    required String pharmacistUid,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final update = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(_ordersCollection.doc(orderId), update);
      batch.update(_usersCollection.doc(patientUid).collection('orders').doc(orderId), update);
      batch.update(_usersCollection.doc(pharmacistUid).collection('orders').doc(orderId), update);
      await batch.commit();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Upload Prescription Image
  Future<String?> uploadPrescription(XFile file) async {
    try {
      String fileName = 'prescriptions/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      
      // Using putData to handle both Web and Mobile
      final bytes = await file.readAsBytes();
      UploadTask uploadTask = ref.putData(bytes);
      
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
