import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../models/order_model.dart';
import 'order_success_screen.dart';
import 'dart:io';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _postalController = TextEditingController();

  XFile? _selectedImage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _townController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescription(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prescription attached successfully!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(String docId, int currentQty, double price, int change) async {
    int newQty = currentQty + change;
    if (newQty < 1) return;
    await FirebaseFirestore.instance.collection('cart').doc(docId).update({
      'quantity': newQty,
      'totalPrice': newQty * price,
    });
  }

  Future<void> _removeItem(String docId) async {
    await FirebaseFirestore.instance.collection('cart').doc(docId).delete();
  }

  void _checkout(List<QueryDocumentSnapshot> cartDocs, double grandTotal) async {
    if (_formKey.currentState!.validate() && cartDocs.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final patientUid = FirebaseAuth.instance.currentUser?.uid;
        if (patientUid == null || patientUid.isEmpty) {
          throw Exception('User not logged in');
        }

        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _dbService.uploadPrescription(_selectedImage!);
        }

        final items = cartDocs.map((doc) => {
          'name': doc['medicineName'],
          'price': doc['price'],
          'quantity': doc['quantity'],
        }).toList();

        final String pharmacyName = (cartDocs.first.data() as Map<String, dynamic>)['pharmacyName'] ?? '';
        final String pharmacistUid = (cartDocs.first.data() as Map<String, dynamic>)['pharmacyId'] ?? '';
        if (pharmacistUid.isEmpty) {
          throw Exception('Missing pharmacyId on cart items');
        }

        final order = OrderModel(
          id: '',
          userId: patientUid,
          userName: _nameController.text,
          userPhone: _phoneController.text,
          email: '', // Not requested
          userAddress: _addressController.text,
          town: _townController.text,
          postalCode: _postalController.text,
          pharmacistUid: pharmacistUid,
          pharmacyName: pharmacyName,
          totalPrice: grandTotal,
          items: items,
          timestamp: DateTime.now(),
          prescriptionUrl: imageUrl,
        );

        await _dbService.placeOrder(order);

        // Delete items from cart
        for (var doc in cartDocs) {
          await _removeItem(doc.id);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessScreen(
                totalAmount: grandTotal,
                medicineName: items.length == 1 ? items[0]['name'] as String : '${items.length} Items',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('cart')
                .where('status', isEqualTo: 'pending')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartDocs = snapshot.data?.docs ?? [];

          if (cartDocs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Your cart is empty!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          double subtotal = 0.0;
          for (var doc in cartDocs) {
            subtotal += (doc['totalPrice'] ?? 0.0).toDouble();
          }
          double deliveryFee = 50.0;
          double grandTotal = subtotal + deliveryFee;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cart Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartDocs.length,
                    itemBuilder: (context, index) {
                      final item = cartDocs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.medication, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['medicineName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(item['pharmacyName'], style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('LKR ${(item['price'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeItem(item.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _QtyButton(icon: Icons.remove, onPressed: () => _updateQuantity(item.id, item['quantity'], item['price'], -1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    _QtyButton(icon: Icons.add, onPressed: () => _updateQuantity(item.id, item['quantity'], item['price'], 1)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Checkout Form
                  const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _townController,
                          decoration: const InputDecoration(labelText: 'Town', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _postalController,
                          decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrescriptionSection(context),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment Method: Cash on Delivery (COD)',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow('Subtotal', 'LKR ${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Delivery Fee', 'LKR ${deliveryFee.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildSummaryRow('Grand Total', 'LKR ${grandTotal.toStringAsFixed(2)}', isTotal: true),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _checkout(cartDocs, grandTotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Buy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              const Text('Add Prescription (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildUploadButton(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () => _pickPrescription(ImageSource.camera)),
              const SizedBox(width: 12),
              _buildUploadButton(icon: Icons.image_rounded, label: 'Gallery', onTap: () => _pickPrescription(ImageSource.gallery)),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 15,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 15, color: Colors.white),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.black : Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.blue.shade800 : Colors.black)),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: Colors.black),
      ),
    );
  }
}
