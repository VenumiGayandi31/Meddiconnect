import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/database_service.dart';

class PharmacistStockScreen extends StatefulWidget {
  const PharmacistStockScreen({super.key});

  @override
  State<PharmacistStockScreen> createState() => _PharmacistStockScreenState();
}

class _PharmacistStockScreenState extends State<PharmacistStockScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditMedicineDialog({MedicineModel? medicineToEdit}) {
    final isEditing = medicineToEdit != null;
    
    final nameController = TextEditingController(text: isEditing ? medicineToEdit.name : '');
    final brandController = TextEditingController(text: isEditing ? medicineToEdit.brand : '');
    final priceController = TextEditingController(text: isEditing ? medicineToEdit.price.toString() : '');
    final stockController = TextEditingController(text: isEditing ? medicineToEdit.stockCount.toString() : '');
    final pharmacyController = TextEditingController(text: isEditing ? medicineToEdit.pharmacyName : '');
    final locationController = TextEditingController(text: isEditing ? medicineToEdit.location : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Medicine Name', Icons.medication),
                _buildTextField(brandController, 'Brand/Manufacturer', Icons.business),
                _buildTextField(priceController, 'Price (LKR)', Icons.attach_money, isNumber: true),
                _buildTextField(stockController, 'Stock Count', Icons.inventory, isNumber: true),
                _buildTextField(pharmacyController, 'Pharmacy Name', Icons.local_pharmacy),
                _buildTextField(locationController, 'Location', Icons.location_on),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final pharmacistUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                if (pharmacistUid.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are not logged in.'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }

                if (nameController.text.trim().isEmpty ||
                    pharmacyController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty ||
                    stockController.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange),
                    );
                  }
                  return;
                }

                final medicine = MedicineModel(
                  id: isEditing ? medicineToEdit.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  brand: brandController.text.trim(),
                  location: locationController.text.trim(),
                  pharmacyName: pharmacyController.text.trim(),
                  pharmacyId: pharmacistUid,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  stockCount: int.tryParse(stockController.text) ?? 0,
                );
                
                try {
                  await _dbService.addMedicine(medicine);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medicine saved successfully.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Medicine'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: const Color(0xFF333333),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacist Portal',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stock Management',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: StreamBuilder<List<MedicineModel>>(
                stream: FirebaseFirestore.instance
                    .collection('medicines')
                    .where('pharmacyId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots()
                    .map((snapshot) => snapshot.docs
                        .map((doc) => MedicineModel.fromFirestore(doc.data(), doc.id))
                        .toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final allMedicines = snapshot.data ?? [];
                  final lowStockCount = allMedicines.where((m) => m.stockCount < 10).length;
                  
                  final filteredMedicines = allMedicines.where((med) {
                    return med.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Medicines', style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 12, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text('${allMedicines.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDF0D5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Low Stock', style: TextStyle(color: Colors.brown.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text('$lowStockCount', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showAddOrEditMedicineDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A5A5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('+ Add New Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            decoration: const InputDecoration(
                              hintText: 'Search medicines...',
                              hintStyle: TextStyle(color: Colors.black26),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text('CURRENT STOCK', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        
                        // List Container
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              ...filteredMedicines.map((medicine) {
                                final isLowStock = medicine.stockCount < 10;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333))),
                                                const SizedBox(height: 4),
                                                Text(medicine.brand, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isLowStock ? const Color(0xFFFDF0D5) : const Color(0xFFE2F0E5),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${medicine.stockCount} units',
                                                  style: TextStyle(
                                                    color: isLowStock ? Colors.brown.shade800 : const Color(0xFF4A7D59),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: () => _showAddOrEditMedicineDialog(medicineToEdit: medicine),
                                                child: Text('Edit', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (medicine != filteredMedicines.last)
                                      Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                                  ],
                                );
                              }),
                              
                              if (filteredMedicines.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(child: Text('No medicines found')),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('... more items', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}