import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nft_cert/admin/requestDate_list.dart';
import 'package:nft_cert/components/event_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class EventSettingScreen extends StatelessWidget {
  final String orgId;
  final String cereId;
  final String eventName;
  final String organizationName;
  final bool verified;

  EventSettingScreen({
    required this.orgId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Function to update the `available` field in Firebase
    Future<void> updateEventAvailability(bool available) async {
      if (verified) {
        await _firestore.collection('certification_event').doc(cereId).update({
          'available': available,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The event cannot start without verification!'),
          ),
        );
      }
    }

    Future<void> _shareQRCode(String cereId) async {
      try {
        // Generate the QR code as an image
        final qrValidationImage = await QrPainter(
          data: cereId,
          version: QrVersions.auto,
          gapless: false,
          color: Colors.black,
          emptyColor: Colors.white,
        ).toImage(300); // 300 is the image size

        // Convert to PNG bytes
        final byteData =
            await qrValidationImage.toByteData(format: ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Get the temporary directory of the device
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code.png').create();

        // Write the QR code PNG to the file
        await file.writeAsBytes(pngBytes);

        // Share the image file using ShareXFiles
        final xFile = XFile(file.path); // Create an XFile from the path
        await Share.shareXFiles([xFile],
            text: 'Check out this certification event');
      } catch (e) {
        print('Error generating or sharing QR code: $e');
      }
    }

    // Function to show the QR Code Dialog
    void showQRCodeDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Event QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200, // Provide a width
                  height: 200, // Provide a height
                  child: QrImageView(
                    data: "https://nft-certification.com/event/" + cereId,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _shareQRCode(
                        "https://nft-certification.com/event/" + cereId);
                  },
                  child: Text('Share'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // StreamBuilder to listen to Firebase data in real-time
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('certification_event')
                    .doc(cereId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error fetching data'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('Event not found'));
                  }

                  // Get the available field from Firestore
                  var eventData = snapshot.data!.data() as Map<String, dynamic>;
                  bool available = eventData['available'] ?? false;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Certification Event',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            available
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 20),
                                    ),
                                    onPressed: () async {
                                      await updateEventAvailability(false);
                                    },
                                    child: Text(
                                      'End Event',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 20),
                                    ),
                                    onPressed: () async {
                                      await updateEventAvailability(true);
                                    },
                                    child: Text(
                                      'Start Event',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      EventCard(
                        orgId: orgId,
                        cereId: cereId,
                        eventName: eventName,
                        organizationName: organizationName,
                        verified: verified,
                        available: available,
                        isClickable: false,
                      ),

                      // Edit and Show Data Buttons
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              onPressed: () {
                                showQRCodeDialog(context);
                              },
                              child: Text(
                                'Show Event QR',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              onPressed: () {
                                // Handle "Show Data" button click
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RequestDataScreen(
                                      orgId: orgId,
                                      cereId: cereId,
                                      eventName: eventName,
                                      organizationName: organizationName,
                                      verified: verified,
                                      available: available,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Show Data',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
