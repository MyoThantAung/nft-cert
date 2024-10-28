import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/admin/requestDate_list.dart';
import 'package:nft_cert/components/QRScanner.dart';

import 'package:nft_cert/components/user_event_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventList extends StatefulWidget {
  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  final TextEditingController _textController = TextEditingController();

  String? scannedText;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String eventID = "";

  // Get Info

  String? uid;
  String? email;
  String? walletAddress;

  // Retrieve user info from SharedPreferences
  Future<void> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
      email = prefs.getString('email');
      walletAddress = prefs.getString('walletAddress');
    });
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
    // Add a listener to check the length of the text in the TextField
    _textController.addListener(() {
      if (_textController.text.length >= 19) {
        setState(() {
          eventID = _textController.text;
          print("28");
        });
      }
    });
  }

  // Method to navigate to the QR scanner
  Future<void> _scanQRCode(BuildContext context) async {
    var result = null;

    result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _textController.text = result; // Set the result to the TextField
      });
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
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 16,
                ),
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
              // QR code input field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter or Scan QR Code',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          _scanQRCode(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Container(
                  child: eventID != ""
                      ? StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('certification_event')
                              .doc(
                                  eventID) // Use the document ID to get the specific event
                              .snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // Check if we have data and if the document exists
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Center(
                                child: Text(
                                  "— No Certification Event Found —",
                                  style: TextStyle(fontSize: 12),
                                ),
                              );
                            }

                            // Extract the event data
                            var eventData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            String cereId = snapshot.data!.id;
                            String orgId = eventData['orgid'];
                            String eventName =
                                eventData['eventName'] ?? 'Unknown Event';
                            String organizationName =
                                eventData['organizationName'] ??
                                    'Unknown Organization';
                            bool verified = eventData["verified"] ?? false;
                            bool available = eventData["available"] ?? false;
                            List<dynamic> studentEmails =
                                eventData['studentEmails'] ?? [];

                            // Check if the user's email is in the studentEmails array
                            if (!studentEmails.contains(email)) {
                              return Center(
                                child: Text(
                                  "— You are not registered for this event —",
                                  style: TextStyle(fontSize: 12),
                                ),
                              );
                            }

                            // Only display the EventCard if both verified and available are true
                            if (verified && available) {
                              return UserEventCard(
                                orgId: orgId,
                                cereId: cereId,
                                eventName: eventName,
                                organizationName: organizationName,
                                verified: verified,
                                available: available,
                                clickable: true,
                              );
                            } else {
                              return Center(
                                child: Text(
                                  "— No Available Certification Event —",
                                  style: TextStyle(fontSize: 12),
                                ),
                              );
                            }
                          },
                        )
                      : SizedBox(),
                ),
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
