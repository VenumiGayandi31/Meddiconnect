import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _currentPharmacyName;

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  String? get currentPharmacyName => _currentPharmacyName;

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  double get totalAmount => subtotal + 50.0; // Adding LKR 50 Delivery Fee

  /// Returns true if added successfully.
  /// Returns false if pharmacy mismatch (caller should show dialog).
  bool addItem(MedicineModel medicine, {int quantity = 1}) {
    if (_items.isEmpty) {
      _currentPharmacyName = medicine.pharmacyName;
    }

    if (medicine.pharmacyName != _currentPharmacyName) {
      return false;
    }

    if (_items.containsKey(medicine.id)) {
      _items.update(
        medicine.id,
        (existingItem) => CartItem(
          medicine: existingItem.medicine,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        medicine.id,
        () => CartItem(medicine: medicine, quantity: quantity),
      );
    }
    notifyListeners();
    return true;
  }

  void removeSingleItem(String medicineId) {
    if (!_items.containsKey(medicineId)) return;

    if (_items[medicineId]!.quantity > 1) {
      _items.update(
        medicineId,
        (existingItem) => CartItem(
          medicine: existingItem.medicine,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(medicineId);
    }
    
    if (_items.isEmpty) {
      _currentPharmacyName = null;
    }
    notifyListeners();
  }

  void removeItem(String medicineId) {
    _items.remove(medicineId);
    if (_items.isEmpty) {
      _currentPharmacyName = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _currentPharmacyName = null;
    notifyListeners();
  }
}
