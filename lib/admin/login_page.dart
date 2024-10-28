import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/admin/home_admin.dart';
import 'package:nft_cert/user/emailConfirm_page.dart';
import 'package:nft_cert/user/forgotPassword_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreenAdmin extends StatefulWidget {
  @override
  State<LoginScreenAdmin> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenAdmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    clearSharedPreferences();
  }

  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("Shared preferences cleared");
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Show a SnackBar for messages
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

// Save info in shared_preferences
  Future<void> saveAdminInfo(String uid, String? email, String orgid,
      String org_name, String org_address, String org_walletAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid); // Save UID
    await prefs.setString('email', email!); // Save email
    await prefs.setString('orgid', orgid);
    await prefs.setString('org_name', org_name);
    await prefs.setString('org_address', org_address);
    await prefs.setString('org_walletAddress', org_walletAddress);
  }

  Future<void> loginWithEmailPassword(String email, String password) async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => emailConfirmScreen()),
          (Route<dynamic> route) =>
              false, // This removes all the previous routes
        );

        showSnackBar('Please verify your email before logging in.');
      } else if (user != null && user.emailVerified) {
        // Check if the user is an admin by querying Firestore
        DocumentSnapshot adminDoc =
            await _firestore.collection('organizations').doc(user.uid).get();

        if (adminDoc.exists) {
          await saveAdminInfo(
              user.uid,
              user.email,
              adminDoc['orgid'],
              adminDoc['org_name'],
              adminDoc['org_address'],
              adminDoc['walletAddress']);
          // Navigate to Admin HomeScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => homeAdminScreen()),
            (Route<dynamic> route) =>
                false, // This removes all the previous routes
          );
        } else {
          showSnackBar('Admin data not found.');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else {
        errorMessage = 'Login failed. Please try again.';
      }
      showSnackBar(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isValidEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              // Admin badge
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'NFT',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Text(
                'Certification',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 50),
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      style: TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      style: TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                String email = emailController.text.trim();
                                String password =
                                    passwordController.text.trim();

                                if (email.isEmpty || password.isEmpty) {
                                  showSnackBar(
                                      'Please enter email and password');
                                } else if (!isValidEmail(email)) {
                                  showSnackBar(
                                      'Please enter a valid email address');
                                } else if (password.length < 8) {
                                  showSnackBar(
                                      'Password must be at least 8 characters long');
                                } else {
                                  loginWithEmailPassword(email, password);
                                }
                              },
                        child: isLoading
                            ? SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 3.0,
                                ),
                              )
                            : Text(
                                'Login',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ForgotPasswordScreen()),
                              );
                            },
                            child: Text('Forgot Password?'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Login As User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
