import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine_model.dart';
import '../services/ocr_service.dart';
import 'cart_screen.dart';
import 'ocr_pharmacy_results_screen.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _scanPrescriptionAndShowPlaces() async {
    try {
      final picker = ImagePicker();
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const ListTile(
                  title: Text('Scan Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Choose an image source'),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      final detectedList = await OCRService.processImageMedicines(image);
      if (!mounted) return;
      if (detectedList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect a medicine name.'), backgroundColor: Colors.orange),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OCRPharmacyResultsScreen(medicineQueries: detectedList),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(MedicineModel medicine, int qty) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('User not logged in');
      }
      final cartCollection = FirebaseFirestore.instance.collection('cart');

      final pendingItems = await cartCollection
          .where('status', isEqualTo: 'pending')
          .where('userId', isEqualTo: uid)
          .get();
      QueryDocumentSnapshot? existingItem;

      if (pendingItems.docs.isNotEmpty) {
        final first = pendingItems.docs.first.data();
        final existingPharmacyId = (first['pharmacyId'] ?? '').toString().trim();
        final existingPharmacyName = (first['pharmacyName'] ?? '').toString().trim();
        final currentPharmacyId = medicine.pharmacyId.trim();

        // Enforce "one pharmacy per cart" using pharmacyId (more reliable than name).
        if (existingPharmacyId.isNotEmpty &&
            currentPharmacyId.isNotEmpty &&
            existingPharmacyId != currentPharmacyId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "You can only add medicines from one pharmacy (${existingPharmacyName.isEmpty ? 'selected pharmacy' : existingPharmacyName}).",
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        try {
          existingItem = pendingItems.docs.firstWhere((doc) {
            final data = doc.data();
            final existingMedicineId = (data['medicineId'] ?? '').toString();
            if (existingMedicineId.isNotEmpty) {
              return existingMedicineId == medicine.id;
            }
            return (data['medicineName'] ?? '').toString() == medicine.name;
          });
        } catch (_) {
          existingItem = null;
        }
      }

      if (existingItem != null) {
        int newQty = (existingItem['quantity'] as int) + qty;
        if (newQty > medicine.stockCount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cannot exceed available stock!"), backgroundColor: Colors.orange),
            );
          }
          return;
        }
        await cartCollection.doc(existingItem.id).update({
          'medicineId': medicine.id,
          'quantity': newQty,
          'totalPrice': medicine.price * newQty,
          // Backfill for older cart docs that didn't have these fields yet
          'pharmacyName': medicine.pharmacyName,
          'pharmacyId': medicine.pharmacyId,
          'userId': uid,
        });
      } else {
        await cartCollection.add({
          'medicineId': medicine.id,
          'medicineName': medicine.name,
          'price': medicine.price,
          'quantity': qty,
          'totalPrice': medicine.price * qty,
          'pharmacyName': medicine.pharmacyName,
          'pharmacyId': medicine.pharmacyId,
          'userId': uid,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${medicine.name} added to Cart!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Scan prescription',
            onPressed: _scanPrescriptionAndShowPlaces,
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                    .collection('cart')
                    .where('status', isEqualTo: 'pending')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              int itemCount = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  itemCount += (doc['quantity'] as int?) ?? 1;
                }
              }
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by medicine name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading medicines'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No medicines found'));
                }

                // Map docs to MedicineModel
                var allMedicines = snapshot.data!.docs
                    .map((doc) => MedicineModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                // Apply search filter on the client side
                var filteredMedicines = allMedicines.where((med) {
                  return med.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredMedicines.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView.builder(
                  itemCount: filteredMedicines.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final medicine = filteredMedicines[index];
                    return GestureDetector(
                      onTap: () {
                        if (medicine.stockCount > 0) {
                          _addToCart(medicine, 1); 
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Out of Stock!"), 
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              medicine.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.local_pharmacy, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(medicine.pharmacyName, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stock: ${medicine.stockCount}', 
                                      style: TextStyle(
                                        color: medicine.stockCount > 0 ? Colors.green.shade700 : Colors.red,
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('LKR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                                Text(
                                  medicine.price.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
