import 'medicine_model.dart';

class CartItem {
  final MedicineModel medicine;
  int quantity;

  CartItem({
    required this.medicine,
    this.quantity = 1,
  });

  double get totalPrice => medicine.price * quantity;
}
