import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/pharmacist_main_holder.dart';
import '../screens/home_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> navigateUser(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userData.exists) {
        // Handle case where user document doesn't exist
        return;
      }

      String role = userData['role']; // 'patient', 'pharmacist', or 'admin'

      if (role == 'pharmacist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PharmacistMainHolder()),
        );
      } else if (role == 'admin') {
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
      } else {
        // Default to Patient / Home Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }
}
