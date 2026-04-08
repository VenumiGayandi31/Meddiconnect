import 'package:flutter/material.dart';
import 'dart:math';

import 'home_page.dart';

class OrderSuccessScreen extends StatelessWidget {
  final double? totalAmount;
  final String? medicineName;
  final String orderId;

  OrderSuccessScreen({super.key, this.totalAmount, this.medicineName})
      : orderId = '#MC-${20240000 + Random().nextInt(10000)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 50, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Order Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Your order has been placed\nsuccessfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Order ID', orderId),
                    const Divider(height: 32),
                    _buildDetailRow('Medicine', medicineName ?? 'Pharmacy Order'),
                    const Divider(height: 32),
                    _buildDetailRow('Payment', 'Cash on Delivery'),
                    const Divider(height: 32),
                    _buildDetailRow('Estimated', '2-4 hrs'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: Text(
                  'Track your order in My Orders',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}
