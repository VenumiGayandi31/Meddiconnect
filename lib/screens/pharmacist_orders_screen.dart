import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';
import 'order_details_screen.dart';

class PharmacistOrdersScreen extends StatefulWidget {
  const PharmacistOrdersScreen({super.key});

  @override
  State<PharmacistOrdersScreen> createState() => _PharmacistOrdersScreenState();
}

class _PharmacistOrdersScreenState extends State<PharmacistOrdersScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isUpdating = false;

  
  final Color darkGray = const Color(0xFF343A40);

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _dbService.updateOrderStatus(
        order.id,
        newStatus,
        patientUid: order.userId,
        pharmacistUid: order.pharmacistUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $newStatus successfully!'),
            backgroundColor: newStatus == 'Accepted' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pharmacist Orders',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<OrderModel>>(
            stream: _dbService.getOrdersForPharmacist(
                FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(darkGray),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          'No Orders Available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final bool isPending = order.status == 'Pending';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(
                              order: order,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tag, size: 18, color: darkGray.withOpacity(0.6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ORD-${order.id.substring(0, 8).toUpperCase()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: darkGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge(order.status),
                                ],
                              ),
                              const Divider(height: 32, thickness: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL AMOUNT',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'LKR ${order.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          color: darkGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isPending)
                                    ElevatedButton(
                                      onPressed: _isUpdating 
                                          ? null 
                                          : () => _updateStatus(order, 'Accepted'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkGray,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                    child: const Text(
                                      'ACCEPT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                              ],
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
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(darkGray)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Accepted':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'Pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
