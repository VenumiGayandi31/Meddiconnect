import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PharmacistRegisterScreen extends StatefulWidget {
  const PharmacistRegisterScreen({super.key});

  @override
  State<PharmacistRegisterScreen> createState() => _PharmacistRegisterScreenState();
}

class _PharmacistRegisterScreenState extends State<PharmacistRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController(); 
  final _pharmacyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  
  final _tradeLicenseController = TextEditingController();
  final _pharmacyLicenseController = TextEditingController();
  final _slmcRegController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _selectedGender = 'Male';

  double? _selectedLat;
  double? _selectedLng;
  bool _isLocationCaptured = false;
  bool _isLoading = false;

  final Color darkGray = const Color(0xFF343A40);

  Future<void> _pickLocation() async {
    try {
      
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
        setState(() {
          _selectedLat = position.latitude;
          _selectedLng = position.longitude;
          _isLocationCaptured = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location Captured Successfully! ✅")),
        );
      }
    } catch (e) {
      print("Error picking location: $e");
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLocationCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pin your pharmacy location first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': _fullNameController.text.trim(),
        'pharmacyName': _pharmacyNameController.text.trim(),
        'ownerName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        
        
        'trade_license_no': _tradeLicenseController.text.trim(),
        'pharmacy_license_no': _pharmacyLicenseController.text.trim(),
        'slmc_registration_no': _slmcRegController.text.trim(),
        
        'gender': _selectedGender,
        'role': 'pharmacist',
        'isApproved': false,
        'isRejected': false,
        'status': 'pending',
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Sent! Admin will verify your licenses.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pharmacy Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: darkGray,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Pharmacist Verification Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide valid registration numbers for admin approval.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              decoration: _inputDecoration('Enter your full name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            
            _buildLabel('Gender'),
            const SizedBox(height: 10),
            Row(
              children: [
                
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Male' ? darkGray : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: darkGray.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.male, color: _selectedGender == 'Male' ? Colors.white : darkGray),
                          const SizedBox(width: 8),
                          Text(
                            'Male',
                            style: TextStyle(
                              color: _selectedGender == 'Male' ? Colors.white : darkGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Female Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Female' ? Colors.pink : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.female, color: _selectedGender == 'Female' ? Colors.white : Colors.pink),
                          const SizedBox(width: 8),
                          Text(
                            'Female',
                            style: TextStyle(
                              color: _selectedGender == 'Female' ? Colors.white : Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(_pharmacyNameController, 'Pharmacy Name', Icons.store),
            _buildField(_phoneController, 'Contact Number', Icons.phone),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "License & ID Verification",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildField(
              _tradeLicenseController,
              'Trade License No (Pradeshiya Sabha)',
              Icons.description_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Trade License Number is required';
                }
                if (value.length < 5) {
                  return 'Enter a valid Trade License number';
                }
                return null;
              },
            ),
            _buildField(
              _pharmacyLicenseController,
              'Pharmacy License No (NMRA)',
              Icons.medical_services_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pharmacy License is required';
                }
                if (!value.toUpperCase().contains('ML') && !value.toUpperCase().contains('PH')) {
                  return 'License must contain ML or PH';
                }
                return null;
              },
            ),
            _buildField(
              _slmcRegController,
              'SLMC Registration No (Pharmacist ID)',
              Icons.badge_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'SLMC Number is required';
                }
                if (value.length < 4) {
                  return 'Enter a valid SLMC number';
                }
                return null;
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            
            _buildField(_emailController, 'Email Address', Icons.email_outlined),
            _buildField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
            
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: !_isLocationCaptured ? Colors.orange : Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isLocationCaptured ? "Location Captured ✅" : "Select Pharmacy Location",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.my_location),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register as Pharmacist', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade300),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkGray, width: 1.5),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: darkGray, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
