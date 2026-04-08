import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pharmacist_main_holder.dart';
import 'home_page.dart'; 
import 'login_screen.dart'; 

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!authSnapshot.hasData) {
          
          return const LoginScreen(); 
        }

        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              String role = userSnapshot.data!['role'] ?? 'patient';

              if (role == 'pharmacist') {
                return const PharmacistMainHolder();
              } else {
                return const HomePage(); 
              }
            }
            return const HomePage();
          },
        );
      },
    );
  }
}
