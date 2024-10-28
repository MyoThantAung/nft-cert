import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/admin/pickimage_mint.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:nft_cert/user/shareNFTPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final String orgId;
  final String userId;
  final String cereId;
  final String tokenId;
  final String eventName;
  final String organizationName;
  bool verified;
  final bool available;
  final bool isTransferred;

  RequestDetailScreen({
    required this.requestId,
    required this.orgId,
    required this.userId,
    required this.cereId,
    required this.tokenId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
    required this.isTransferred,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool isLoading = false;
  bool isTloading = false;
  bool nftExists = false;

  late String tokenId;

  final ApiService apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    checkNftStatus();
    getAttributes();
  }

  Map<String, dynamic>? attributes;
  bool isAttributesLoading = true;

  // Function to fetch attributes from Firestore
  void getAttributes() async {
    try {
      QuerySnapshot reqform = await _firestore
          .collection('certification_request_form')
          .where('userId', isEqualTo: widget.userId)
          .where('cereId', isEqualTo: widget.cereId)
          .limit(1)
          .get();

      if (reqform.docs.isNotEmpty) {
        DocumentSnapshot documentData = reqform.docs.first;
        var attributesData = documentData['attributes'] ?? {};

        setState(() {
          attributes = Map<String, dynamic>.from(attributesData);
          isAttributesLoading = false;
        });
      } else {
        setState(() {
          isAttributesLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attributes: $e');
      setState(() {
        isAttributesLoading = false;
      });
    }
  }

  // Function to check if NFT already exists for this user, org, and event
  Future<void> checkNftStatus() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(
              "minted_certification") // Assuming 'nfts' is your collection name
          .where('userId', isEqualTo: widget.userId)
          .where('orgId', isEqualTo: widget.orgId)
          .where('cereId', isEqualTo: widget.cereId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = snapshot.docs.first;
        tokenId = documentSnapshot["nftTokenId"];
        print(tokenId);
        setState(() {
          nftExists = true; // NFT already exists
        });
      }
    } catch (e) {
      print('Error checking NFT status: $e');
    }
  }

  // Function to update the 'verified' field in Firestore
  Future<void> updateVerifyForm(bool verified) async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      await FirebaseFirestore.instance
          .collection("certification_request_form")
          .doc(widget.requestId)
          .update({
        'verified': verified, // Update the verified field
      });

      setState(() {
        widget.verified = verified;
        isLoading = false; // End loading
      });
    } catch (e) {
      print('Error verifying form: $e');
      setState(() {
        isLoading = false; // End loading on error
      });
    }
  }

  // Function to handle NFT transfer
  Future<void> transferNFT() async {
    if (!widget.isTransferred) {
      setState(() {
        isTloading = true; // End loading on error
      });

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      print("Organization : " + org_walletAddress!);
      print("User : " + userDoc['walletAddress']);
      print("Token : " + tokenId);

      if (userDoc.exists) {
        final result =
            await apiService.transferNFT(userDoc['walletAddress'], tokenId);

        print("Result : " + result.toString());

        if (result.isNotEmpty) {
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection("minted_certification") // Your collection name
              .where('userId', isEqualTo: widget.userId)
              .where('orgId', isEqualTo: widget.orgId)
              .where('cereId', isEqualTo: widget.cereId)
              .limit(1)
              .get();

          // Loop through each document and update the 'isTransferred' field
          for (var doc in snapshot.docs) {
            await doc.reference.update({
              'isTransferred': true,
            });
          }

          setState(() {
            isTloading = false; // End loading on error
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('NFT Transfer Success!')),
          );

          Navigator.pop(context);
        } else {
          setState(() {
            isTloading = false; // End loading on error
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Something Wrong!')),
          );
        }
      } else {
        setState(() {
          isTloading = false; // End loading on error
        });
      }
    } else {
      // Show NFT Detail

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NFTCertificationScreen(
            tokenId: tokenId,
            share: false,
          ),
        ),
      );
    }
  }

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
              isTloading
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
                              "Transfering NFT to Student...",
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          child: isAttributesLoading
                              ? Center(child: CircularProgressIndicator())
                              : attributes == null
                                  ? Center(child: Text('No attributes found'))
                                  : Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: DataTable(
                                                columns: [
                                                  DataColumn(
                                                      label: Text('Key')),
                                                  DataColumn(
                                                      label: Text('Value')),
                                                ],
                                                rows: attributes!.entries
                                                    .map(
                                                      (entry) => DataRow(
                                                        cells: [
                                                          DataCell(
                                                              Text(entry.key)),
                                                          DataCell(
                                                            Text(
                                                              entry.value
                                                                  .toString(),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                        ),

                        // Pushes the buttons to the bottom
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Verify Form Button
                              InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        if (widget.verified) {
                                          updateVerifyForm(false);
                                        } else {
                                          updateVerifyForm(true);
                                        }
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !widget.verified
                                        ? Colors.green
                                        : Colors
                                            .red, // Button color depending on verified status
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 15.0),
                                    child: isLoading
                                        ? SizedBox(
                                            height: 20.0,
                                            width: 20.0,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 3.0,
                                            ),
                                          )
                                        : Text(
                                            widget.verified
                                                ? 'Unverify Form'
                                                : 'Verify Form',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                              // Create or Transfer NFT Button
                              InkWell(
                                onTap: nftExists
                                    ? () {
                                        if (widget.verified) {
                                          transferNFT();
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Please Verified First!')),
                                          );
                                        }
                                      }
                                    : () {
                                        if (widget.verified) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  pickImageMintScreen(
                                                requestId: widget.requestId,
                                                orgId: widget.orgId,
                                                userId: widget.userId,
                                                cereId: widget.cereId,
                                                eventName: widget.eventName,
                                                organizationName:
                                                    widget.organizationName,
                                                verified: widget.verified,
                                                available: widget.available,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Please Verified First!')),
                                          );
                                        }
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 190, 145,
                                        255), // Light grey background
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 15.0),
                                    child: Text(
                                      nftExists
                                          ? widget.isTransferred
                                              ? 'NFT Detail'
                                              : 'Transfer NFT'
                                          : 'Create NFT',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
          top: 0,
          bottom: 30,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              iconSize: 30,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
