import 'dart:io';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nft_cert/admin/nftsuccessdetail.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import 'dart:typed_data';

class pickImageMintScreen extends StatefulWidget {
  final String requestId;
  final String orgId;
  final String userId;
  final String cereId;
  final String eventName;
  final String organizationName;
  bool verified;
  final bool available;

  pickImageMintScreen({
    required this.requestId,
    required this.orgId,
    required this.userId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
  });

  @override
  State<pickImageMintScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<pickImageMintScreen> {
  final ApiService apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  File? _imageFile;

  String? uid;
  String? email;
  String? orgid;
  String? org_name;
  String? org_address;
  String? org_walletAddress;

  // Retrieve user info from SharedPreferences
  Future<void> getAdminInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
      email = prefs.getString('email');
      orgid = prefs.getString('orgid');
      org_name = prefs.getString('org_name');
      org_address = prefs.getString('org_address');
      org_walletAddress = prefs.getString('org_walletAddress');
    });
    print("Shared Loaded");
  }

  @override
  void initState() {
    super.initState();
    getAdminInfo();
    getJsonAttribute();
    // Fetch user info when the screen loads
  }

  String jsonAttributes = "";

  Future<void> getJsonAttribute() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot reqform = await _firestore
        .collection('certification_request_form')
        .where('userId', isEqualTo: widget.userId)
        .where('cereId', isEqualTo: widget.cereId)
        .limit(1)
        .get();

    if (reqform.docs.isNotEmpty) {
      // Check if the document exists

      // Assuming 'attributes' is a field in the document
      DocumentSnapshot documentData = reqform.docs.first;
      var attributes = documentData != null ? documentData['attributes'] : '';

      setState(() {
        jsonAttributes = jsonEncode(attributes);
        // Format the JSON string with indentation

        isLoading = false;
      });
    } else {
      showSnackBar("No document found");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // XOR Encryption function
  String xorEncrypt(String data, String key) {
    List<int> encryptedBytes = [];
    for (int i = 0; i < data.length; i++) {
      encryptedBytes.add(data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }
    return base64Encode(
        encryptedBytes); // Convert encrypted bytes to Base64 string
  }

  Future<void> mint() async {
    setState(() {
      isLoading = true;
    });

    // Convert image file to Base64
    String? base64Image;
    if (_imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    } else {
      showSnackBar('Please pick an image.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userId).get();

    if (userDoc.exists) {
      if (org_walletAddress != null && userDoc['walletAddress'] != null) {
// Assume the recipient's public key is stored in the userDoc
        String userKey = userDoc['privateKey'];

        final iv = encrypt.IV.fromLength(16);

        // Encrypt jsonAttributes and base64Image separately with the custom AES key
        final encryptedJsonAttributes = xorEncrypt(jsonAttributes, userKey);

        print("org_walletAddress : " + org_walletAddress!);
        print("user_address : " + userDoc['walletAddress']);
        print("User ID : " + widget.userId);
        print("Event ID : " + widget.cereId);

        // Call the API to mint the NFT and get the returned data
        final result = await apiService.mintNFT(userDoc['walletAddress'],
            widget.userId, widget.cereId, encryptedJsonAttributes, base64Image);

        setState(() {
          isLoading = false;
        });

        if (result['error'] == null && result['txHash'] != null) {
          await _firestore.collection('minted_certification').add({
            'cereId': widget.cereId,
            'nftTokenId': result['tokenId'],
            'orgId': widget.orgId,
            'userId': widget.userId,
            'isTransferred': false,
          }).then((_) async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => nftSuccessDetailScreen(
                  transactionHash: result['txHash'] ?? 'Unknown',
                  timestamp: result['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                              result['timestamp'] * 1000)
                          .toString()
                      : 'Unknown',
                  tokenId: result['tokenId'] ?? 'Unknown',
                  mintedAddress: result['mintedAddress'] ?? 'Unknown',
                  contractAddress: result['contractAddress'] ?? 'Unknown',
                  orgName: widget.organizationName,
                ),
              ),
            );
          }).catchError((error) async {
            showSnackBar('Failed to save data to Firestore: $error');
            setState(() {
              isLoading = false;
            });
          });
        } else {
          showSnackBar(result['error']);
          setState(() {
            isLoading = false;
          });
        }
      } else {
        showSnackBar('Somethings Wrong!');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      showSnackBar('User data not found.');
      setState(() {
        isLoading = false;
      });
    }
    // Return JSON string
  }

  // Show a SnackBar for messages
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to update the 'verified' field to true or false in Firestore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin badge and title
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 5),
                child: Row(
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
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NFT',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Certification',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              isLoading
                  ? Container(
                      width: double.infinity, // Fills the width
                      height: 300, // Fills the height
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Center items vertically
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Center items horizontally
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Image.asset(
                                'assets/images/loading.gif', // Your loading GIF here
                                width: 70, // Adjust size as needed
                                height: 70,
                              ),
                            ),
                            Text(
                              "Creating NFT",
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    )
                  :
                  // Certification Image Picker
                  Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: _imageFile == null
                                  ? Center(
                                      child: Text(
                                        "Pick Certification Image",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Create NFT Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Add the action for creating the NFT
                              mint();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 190, 145, 255),
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 40.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Create NFT',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // JSON Data Form Display
                        Text(
                          'Data Form',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Text(
                              jsonAttributes,
                              style: TextStyle(
                                  fontSize: 14, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
