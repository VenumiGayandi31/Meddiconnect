 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class PharmacistProfileScreen extends StatelessWidget {
  const PharmacistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color darkGray = Color(0xFF343A40);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extract all fields from Firestore
          String fullName = 'Pharmacist';
          String email = user?.email ?? 'Not Available';
          String phone = 'Not Set';
          String pharmacyName = 'Not Set';
          String gender = 'Not Set';
          String tradeLicense = 'Not Set';
          String pharmacyLicense = 'Not Set';
          String slmcReg = 'Not Set';
          String status = 'pending';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            fullName = data['fullName'] ?? data['ownerName'] ?? fullName;
            email = data['email'] ?? email;
            phone = data['phone'] ?? 'Not Set';
            pharmacyName = data['pharmacyName'] ?? 'Not Set';
            gender = data['gender'] ?? 'Not Set';
            tradeLicense = data['trade_license_no'] ?? 'Not Set';
            pharmacyLicense = data['pharmacy_license_no'] ?? 'Not Set';
            slmcReg = data['slmc_registration_no'] ?? 'Not Set';
            status = data['status'] ?? 'pending';
          }

          final Color genderColor =
              gender == 'Female' ? Colors.pink : Colors.blue;
          final IconData genderIcon = gender == 'Female'
              ? Icons.female_rounded
              : Icons.male_rounded;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Profile Header Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: darkGray.withOpacity(0.2), width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              darkGray.withOpacity(0.08),
                          child: const Icon(Icons.local_pharmacy_rounded,
                              size: 50, color: darkGray),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(fullName,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(pharmacyName,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(email,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                      const SizedBox(height: 14),
                      // Gender Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: genderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(genderIcon, size: 16, color: genderColor),
                            const SizedBox(width: 6),
                            Text(gender,
                                style: TextStyle(
                                    color: genderColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Approval Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: status == 'approved'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status == 'approved'
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_empty_rounded,
                              size: 14,
                              color: status == 'approved'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status == 'approved'
                                  ? 'Approved'
                                  : 'Pending Approval',
                              style: TextStyle(
                                color: status == 'approved'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Personal Info Section ──
                _sectionCard(
                  title: 'Personal Information',
                  children: [
                    _detailRow(Icons.phone_outlined, 'Phone', phone,
                        Colors.teal),
                    _divider(),
                    _detailRow(Icons.email_outlined, 'Email', email,
                        Colors.deepPurple),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Pharmacy Info Section ──
                _sectionCard(
                  title: 'Pharmacy Details',
                  children: [
                    _detailRow(Icons.store_outlined, 'Pharmacy Name',
                        pharmacyName, Colors.indigo),
                  ],
                ),

                const SizedBox(height: 12),

                // ── License Section ──
                _sectionCard(
                  title: 'License & Verification IDs',
                  children: [
                    _detailRow(Icons.description_outlined, 'Trade License No',
                        tradeLicense, Colors.brown),
                    _divider(),
                    _detailRow(Icons.medical_services_outlined,
                        'Pharmacy License No (NMRA)', pharmacyLicense,
                        Colors.red),
                    _divider(),
                    _detailRow(Icons.badge_outlined, 'SLMC Registration No',
                        slmcReg, Colors.blue),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Logout Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text('MediConnect v1.0.0',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: Colors.grey.shade100, height: 1);
}
