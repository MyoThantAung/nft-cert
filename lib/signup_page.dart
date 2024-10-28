import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:nft_cert/user/emailConfirm_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class signupScreen extends StatefulWidget {
  @override
  State<signupScreen> createState() => _signupScreenState();
}

class _signupScreenState extends State<signupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  final ApiService apiService = ApiService(); // Initialize the ApiService

  Future<void> signUpWithEmailPassword(String email, String password) async {
    setState(() {
      isLoading = true;
    });

    try {
      final walletInfo = await apiService.createWallet();

      if (walletInfo.isNotEmpty) {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        // Store the user's data in Firestore
        await _firestore.collection('users').doc(user!.uid).set({
          'createDate':
              FieldValue.serverTimestamp(), // Save current server time
          'email': user.email,
          'userid': user.uid,
          'walletAddress': walletInfo['walletAddress'],
          'privateKey': walletInfo['privateKey'],
        }).then((_) async {
          // Firestore write was successful

          // Send email verification
          if (userCredential.user != null &&
              !userCredential.user!.emailVerified) {
            await userCredential.user!.sendEmailVerification();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => emailConfirmScreen()),
            );
            showSnackBar(
                'Verification email has been sent. Please check your email.');
          }
        }).catchError((error) async {
          // Handle Firestore error

          await user.delete();

          showSnackBar('Failed to save data to Firestore: $error');
        });

        setState(() {
          isLoading = false; // Stop loading animation
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false; // Stop loading animation
      });

      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else {
        errorMessage = 'Sign up failed. Please try again.';
      }

      // Show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading animation
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  bool isValidEmail(String email) {
    // Simple regex for email validation
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    // Regex to check for at least 1 alphabet, 1 number, and 1 special character
    String pattern =
        r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                      'Sign Up',
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
                    TextField(
                      controller: confirmPasswordController,
                      style: TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
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
                                String confirmPassword =
                                    confirmPasswordController.text.trim();

                                if (email.isEmpty || password.isEmpty) {
                                  showSnackBar(
                                      'Please enter email and password');
                                } else if (password != confirmPassword) {
                                  showSnackBar('Password do not match!');
                                } else if (!isValidEmail(email)) {
                                  showSnackBar(
                                      'Please enter a valid email address');
                                } else if (!isValidPassword(password)) {
                                  showSnackBar(
                                      'Password must be at least 8 characters long, include a letter, a number, and a special character');
                                } else {
                                  signUpWithEmailPassword(email, password);
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
                                'Sign Up',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Continue to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
