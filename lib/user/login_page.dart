import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import your HomeScreen
import 'package:nft_cert/admin/login_page.dart';
import 'package:nft_cert/user/emailConfirm_page.dart';
import 'package:nft_cert/user/forgotPassword_page.dart';
import 'package:nft_cert/user/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../signup_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false; // Loading flag to show the progress indicator

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

  // Save user info in shared_preferences
  Future<void> saveUserInfo(String uid, String? email, String walletAddress,
      String privateKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid); // Save UID
    await prefs.setString('email', email!);
    await prefs.setString('walletAddress', walletAddress);
    await prefs.setString('privateKey', privateKey);
  }

  Future<void> loginWithEmailPassword(String email, String password) async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = _auth.currentUser;

      // Check if the user is an admin by querying Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        if (user != null && !user.emailVerified) {
          // If the email is not verified, navigate to EmailConfirmScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => emailConfirmScreen()),
            (Route<dynamic> route) =>
                false, // This removes all the previous routes
          );

          showSnackBar('Please verify your email before logging in.');
        } else if (user != null && user.emailVerified) {
          await saveUserInfo(user.uid, user.email, userDoc['walletAddress'],
              userDoc['privateKey']);

          print("User ID : " + user.uid);

          // If the email is verified, navigate to HomeScreen

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => homeScreen()),
            (Route<dynamic> route) =>
                false, // This removes all the previous routes
          );
        }
      } else {
        showSnackBar('User data not found.');
      }
    } on FirebaseAuthException catch (e) {
      // Show error if Firebase authentication fails
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
      showSnackBar(e.code);
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
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
          // Prevents overflow on smaller screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
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
                                height: 20.0, // Adjust height as needed
                                width: 20.0, // Adjust width as needed
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth:
                                      3.0, // Adjust thickness of the indicator
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
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => signupScreen()),
                              );
                            },
                            child: Text('Create New Account'),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginScreenAdmin()),
                    );
                  },
                  child: Text('Login As Admin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
