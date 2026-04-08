 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../models/order_model.dart';
import 'order_success_screen.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final MedicineModel? medicine;
  final double? totalAmount;
  final List<CartItem>? cartItems;
  final XFile? prescriptionImage;

  const DeliveryDetailsScreen({
    super.key,
    this.medicine,
    this.totalAmount,
    this.cartItems,
    this.prescriptionImage,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _postalController = TextEditingController();

  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.prescriptionImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50, // පින්තූරයේ size එක අඩු කරන්න
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
      
      // පින්තූරය තෝරගත්ත ගමන් පොඩි message එකක් පෙන්වන්නත් පුළුවන්
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image Selected Successfully!")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _townController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _confirmOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      
      final String customerEmail = _emailController.text.trim();
      final cart = Provider.of<CartProvider>(context, listen: false);
      
      try {
        final patientUid = FirebaseAuth.instance.currentUser?.uid;
        if (patientUid == null || patientUid.isEmpty) {
          throw Exception('User not logged in');
        }

        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _dbService.uploadPrescription(_selectedImage!);
          if (imageUrl == null) {
            throw Exception('Failed to upload prescription image');
          }
        }

        final String pharmacistUid = widget.medicine != null
            ? widget.medicine!.pharmacyId
            : (cart.items.isNotEmpty ? cart.items.values.first.medicine.pharmacyId : '');
        final String pharmacyName = widget.medicine != null
            ? widget.medicine!.pharmacyName
            : (cart.currentPharmacyName ?? '');
        if (pharmacistUid.isEmpty) {
          throw Exception('Missing pharmacyId for this order');
        }

        final order = OrderModel(
          id: '', 
          userId: patientUid, 
          userName: _nameController.text,
          userPhone: _phoneController.text,
          email: customerEmail,
          userAddress: _addressController.text,
          town: _townController.text,
          postalCode: _postalController.text,
          pharmacistUid: pharmacistUid,
          pharmacyName: pharmacyName,
          totalPrice: widget.totalAmount ?? (widget.medicine != null ? (widget.medicine!.price + 50.0) : cart.totalAmount),
          items: widget.medicine != null 
            ? [{'name': widget.medicine!.name, 'price': widget.medicine!.price, 'quantity': 1}]
            : cart.items.values.map((i) => {
                'name': i.medicine.name,
                'price': i.medicine.price,
                'quantity': i.quantity
              }).toList(),
          timestamp: DateTime.now(),
          prescriptionUrl: imageUrl,
        );

        await _dbService.placeOrder(order);
        
        if (widget.medicine == null) {
          cart.clearCart();
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessScreen(
                medicineName: widget.medicine?.name,
                totalAmount: widget.totalAmount ?? (widget.medicine != null ? (widget.medicine!.price + 50.0) : cart.totalAmount),
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
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  final bool isSingleOrder = widget.medicine != null;
                  
                  
                  final double displayPrice = isSingleOrder 
                    ? (widget.totalAmount ?? (widget.medicine!.price + 50.0)) 
                    : (widget.totalAmount ?? cart.totalAmount);
                  
                  String displayName;
                  if (isSingleOrder) {
                    displayName = widget.medicine!.name;
                  } else {
                    final int count = widget.cartItems?.length ?? cart.itemCount;
                    displayName = '$count Items (${cart.currentPharmacyName ?? 'Order'})';
                  }

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          'LKR ${displayPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _townController,
                decoration: const InputDecoration(labelText: 'Town', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postalController,
                decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Prescription",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Camera Button
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, color: Colors.green, size: 30),
                      ),
                      // Gallery Button
                      IconButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 10),
                      
                      // පින්තූරය තෝරාගෙන තිබේ නම් පමණක් මේ කොටස පෙන්වන්න
                      if (_selectedImage != null)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 5),
                            Text(
                              "Prescription Uploaded ✅",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              
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
                        'This order will be processed via Cash on Delivery (COD). Please have the exact amount ready upon delivery.',
                        style: TextStyle(color: Colors.blue.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              
              ElevatedButton(
                onPressed: _isUploading ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
