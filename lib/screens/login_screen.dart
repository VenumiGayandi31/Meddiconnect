import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_panel.dart';
import 'pharmacist_main_holder.dart';
import 'home_page.dart'; 
import 'pharmacist_register_screen.dart';
import 'patient_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email first")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent. Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reset error: ${e.message ?? e.code}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reset error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User record not found");
      }

      String role = userDoc['role'] ?? 'patient';

      if (mounted) {
        if (role == 'admin') {
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
          );
        } else if (role == 'pharmacist') {
          // Check pharmacist status in 'users' collection
          bool isApproved = (userDoc.data() as Map<String, dynamic>).containsKey('isApproved') 
              ? userDoc['isApproved'] == true 
              : false;
          bool isRejected = (userDoc.data() as Map<String, dynamic>).containsKey('isRejected') 
              ? userDoc['isRejected'] == true 
              : false;

          if (isApproved) {
            // Approve වෙලා නම් Dashboard එකට යවනවා
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PharmacistMainHolder()),
            );
          } else if (isRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Your application has been rejected. Please contact support."),
                backgroundColor: Colors.red,
              ),
            );
            await FirebaseAuth.instance.signOut();
          } else {
            // තවම Pending නම් Message එකක් පෙන්වනවා
            _showPendingDialog();
            // වැදගත්: Pending නිසා Log out කරවන එක හොඳයි නැත්නම් App එකේ එයා ලොග් වෙලා වගේ ඉඳියි
            await FirebaseAuth.instance.signOut(); 
          }
        } else {
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.message ?? e.code}"),
          backgroundColor: Colors.red,
        ));
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          
          Container(
            height: size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  
                  
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.blueAccent, size: 50),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to MediConnect',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration('you@email.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 24),
                  
              
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('********'),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendPasswordReset, 
                      child: const Text('Forgot password?', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4A4A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientRegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Create New Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  const Text('Are you a pharmacist?', style: TextStyle(color: Colors.black38, fontSize: 13)),
                  const SizedBox(height: 8),
                  
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PharmacistRegisterScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Register as Pharmacist',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A4A4A), width: 1.5),
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // පිටත එබූ විට වැසෙන්නේ නැත
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Account Pending", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Your account is still under review by the administrator. Please wait for approval.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
