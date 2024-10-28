import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/admin/event_creation.dart';
import 'package:nft_cert/components/event_card.dart';
import 'package:nft_cert/components/nft_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class homeAdminScreen extends StatefulWidget {
  @override
  State<homeAdminScreen> createState() => _main_pageState();
}

class _main_pageState extends State<homeAdminScreen> {
  final PageController _pageController = PageController();

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
      org_address = prefs.getString('org_walletAddress');
    });
  }

  @override
  void initState() {
    super.initState();
    getAdminInfo();

    // Fetch user info when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Admin badge
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 0,
                top: 0,
                bottom: 5,
              ),
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
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 0,
                bottom: 10,
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
            SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('certification_event')
                    .where('orgid', isEqualTo: orgid)
                    .orderBy("createDate")
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  // Check if we have data and if there are events
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "— Any Saved Certification Event Yet —",
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }

                  // Display list of saved certification events
                  final events = snapshot.data!.docs.reversed.toList();
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      var eventData =
                          events[index].data() as Map<String, dynamic>;
                      String orgId = eventData['orgid'];
                      String cereId = events[index].id;
                      String eventName =
                          eventData['eventName'] ?? 'Unknown Event';
                      String organizationName = eventData['organizationName'] ??
                          'Unknown Organization';
                      bool verified = eventData["verified"] ?? false;
                      bool available = eventData["available"] ?? false;

                      return EventCard(
                        orgId: orgId,
                        cereId: cereId,
                        eventName: eventName,
                        organizationName: organizationName,
                        verified: verified,
                        available: available,
                        isClickable: true,
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
          ],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.add_box),
              iconSize: 30,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => eventCreationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
