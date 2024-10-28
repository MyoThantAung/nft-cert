import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class nftSuccessDetailScreen extends StatefulWidget {
  final String transactionHash;
  final String timestamp;
  final String tokenId;
  final String mintedAddress;
  final String contractAddress;
  final String orgName;

  nftSuccessDetailScreen({
    required this.transactionHash,
    required this.timestamp,
    required this.tokenId,
    required this.mintedAddress,
    required this.contractAddress,
    required this.orgName,
  });

  @override
  State<nftSuccessDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<nftSuccessDetailScreen> {
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

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    Center(
                      child: Text(
                        'Successfully Created NFT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Container for NFT details
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFEFEF), // Light grey color
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Timestamp', widget.timestamp),
                          SizedBox(height: 10),
                          _buildDetailRow(
                              'Transaction Hash', widget.transactionHash),
                          SizedBox(height: 10),
                          _buildDetailRow('Token ID', widget.tokenId),
                          SizedBox(height: 10),
                          _buildDetailRow(
                              'Created Address', widget.mintedAddress),
                          SizedBox(height: 10),
                          _buildDetailRow('Organization', widget.orgName),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // View on Polyscan Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          String url = 'https://polygonscan.com/tx/' +
                              widget.transactionHash;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple, // Button color
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'View on Polyscan',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Back Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Add your logic for going back
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          //primary: Colors.grey[300], // Light grey button color
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build rows with titles and values
  Widget _buildDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
