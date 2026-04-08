import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isUpdating = false;

  final Color darkGray = const Color(0xFF343A40);

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _dbService.updateOrderStatus(
        widget.order.id,
        newStatus,
        patientUid: widget.order.userId,
        pharmacistUid: widget.order.pharmacistUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $newStatus Successfully!'),
            backgroundColor: newStatus == 'Accepted' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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
    final order = widget.order;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const Text(
                  'Prescription:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: order.prescriptionUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            child: Image.network(
                              order.prescriptionUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                    SizedBox(height: 8),
                                    Text('Failed to load image'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.no_photography_outlined, color: Colors.grey, size: 48),
                              SizedBox(height: 8),
                              Text('No Prescription Uploaded', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                
                const Text(
                  'Customer Details:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                _buildInfoCard([
                  _infoTile(Icons.person_outline, 'Name', order.userName),
                  _infoTile(Icons.phone_outlined, 'Phone', order.userPhone),
                  _infoTile(Icons.email_outlined, 'Email', order.email),
                  _infoTile(Icons.location_on_outlined, 'Address', '${order.userAddress}, ${order.town}'),
                  _infoTile(Icons.pin_drop_outlined, 'Postal Code', order.postalCode),
                ]),
                const SizedBox(height: 32),

                
                const Text(
                  'Order Items:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                _buildItemsList(order.items),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      'LKR ${order.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkGray),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Action Buttons
                if (order.status == 'Pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () => _updateStatus('Accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUpdating ? null : () => _updateStatus('Rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: order.status == 'Accepted' ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: order.status == 'Accepted' ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        'Order ${order.status}',
                        style: TextStyle(
                          color: order.status == 'Accepted' ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Qty: ${item['quantity']}'),
            trailing: Text('LKR ${(item['price'] * item['quantity']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
