import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class NFTCertificationScreen extends StatefulWidget {
  final String tokenId;
  final bool share;

  NFTCertificationScreen({required this.tokenId, required this.share});

  @override
  State<NFTCertificationScreen> createState() => _NFTCertificationScreenState();
}

class _NFTCertificationScreenState extends State<NFTCertificationScreen> {
  final ApiService apiService = ApiService();
  String imageUrl = '';
  String baseUrl = 'https://blue-tricky-wombat-943.mypinata.cloud/ipfs/';
  bool isLoading = true; // Track loading state

  bool isVerified = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String org_name = "";

  bool isExpired = false; // Add this to track expiration

  // XOR Encryption function
  String xorEncrypt(String input, String key) {
    List<int> inputBytes = utf8.encode(input);
    List<int> keyBytes = utf8.encode(key);
    List<int> outputBytes = List<int>.generate(inputBytes.length,
        (i) => inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    return base64UrlEncode(outputBytes);
  }

  // XOR Decryption function
  String xorDecrypt(String base64Input, String key) {
    List<int> inputBytes = base64Url.decode(base64Input);
    List<int> keyBytes = utf8.encode(key);
    List<int> outputBytes = List<int>.generate(inputBytes.length,
        (i) => inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    return utf8.decode(outputBytes);
  }

  void shareLink() async {
    final DateTime now = DateTime.now();
    final DateTime expirationTime = now.add(Duration(minutes: 5));
    final int expirationTimestamp = expirationTime.millisecondsSinceEpoch;

    // Create data to encrypt
    Map<String, dynamic> dataToEncrypt = {
      'tokenId': widget.tokenId,
      'timestamp': expirationTimestamp,
    };

    String jsonString = jsonEncode(dataToEncrypt);

    // Encrypt data
    String encryptedData = xorEncrypt(jsonString, 'gdtyhsg4uy2twg1f2vwg2f');

    // Construct the shareable link
    String shareableLink =
        'https://nft-certification.com/verified/$encryptedData';

    // Share the link
    Share.share(
      shareableLink,
      subject: 'NFT Certification',
    );
  }

  Future<void> _shareQRCode(String link) async {
    try {
      // Generate the QR code as an image
      final qrValidationImage = await QrPainter(
        data: link,
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
      await Share.shareXFiles([xFile], text: link);
    } catch (e) {
      print('Error generating or sharing QR code: $e');
    }
  }

  // Function to show the QR Code Dialog
  void showQRCodeDialog(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime expirationTime = now.add(Duration(minutes: 10));
    final int expirationTimestamp = expirationTime.millisecondsSinceEpoch;

    // Create data to encrypt
    Map<String, dynamic> dataToEncrypt = {
      'tokenId': widget.tokenId,
      'timestamp': expirationTimestamp,
    };

    String jsonString = jsonEncode(dataToEncrypt);

    // Encrypt data
    String encryptedData = xorEncrypt(jsonString, 'gdtyhsg4uy2twg1f2vwg2f');

    // Construct the shareable link
    String shareableLink =
        'https://nft-certification.com/verified/$encryptedData';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share verifiable NFT Certification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200, // Provide a width
                height: 200, // Provide a height
                child: QrImageView(
                  data: shareableLink,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _shareQRCode(shareableLink);
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

  @override
  void initState() {
    super.initState();
    fetchNFTData();
  }

  Future<void> fetchNFTData() async {
    String tokenId = widget.tokenId;
    BigInt? tokenIdNumber = BigInt.tryParse(tokenId);
    String decryptedTokenId = '';
    int timestamp = 0;

    print(tokenId);

    if (tokenIdNumber != null) {
      // tokenId is a number, proceed as before
      decryptedTokenId = tokenId;

      print("Int");
    } else {
      // tokenId is an encrypted code
      try {
        String decryptedString = xorDecrypt(tokenId, 'gdtyhsg4uy2twg1f2vwg2f');
        // Parse JSON
        Map<String, dynamic> data = jsonDecode(decryptedString);
        decryptedTokenId = data['tokenId'];
        timestamp = data['timestamp'];

        // Check timestamp
        if (timestamp < DateTime.now().millisecondsSinceEpoch) {
          // Show expired
          setState(() {
            isLoading = false;
            isVerified = false;
            isExpired = true;
          });
          return;
        }
      } catch (e) {
        // Decryption or parsing failed
        setState(() {
          isLoading = false;
          isVerified = false;
        });
        return;
      }
    }

    // Proceed with fetching data using decryptedTokenId
    final result = await apiService.getNFTData(decryptedTokenId);
    final resultToken = await apiService.getTokenInfo(decryptedTokenId);

    print("Result : " + result.toString());
    print("ResultToken : " + resultToken.toString());

    var userDoc = await _firestore
        .collection('certification_event')
        .doc(resultToken['eventId'])
        .get();

    var nft = await _firestore
        .collection('minted_certification')
        .where("orgId", isEqualTo: userDoc["orgid"])
        .where("userId", isEqualTo: resultToken['userId'])
        .where("nftTokenId", isEqualTo: decryptedTokenId)
        .get();

    if (result.isNotEmpty && userDoc.exists) {
      String ipfsHash = result['image'];
      setState(() {
        imageUrl = baseUrl + ipfsHash;
        org_name = userDoc["organizationName"];
        isLoading = false;
        if (nft.docs.isNotEmpty) {
          isVerified = true;
        } else {
          print("NFT Empty");
        }
      });
    } else {
      setState(() {
        isLoading = false; // Stop loading if no data is found
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        org_name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      org_name.isNotEmpty
                          ? Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 15,
                            )
                          : Container(),
                    ],
                  ),
                  org_name.isNotEmpty
                      ? widget.share
                          ? InkWell(
                              onTap: () {
                                showQRCodeDialog(context);
                              },
                              child: Icon(Icons.ios_share_outlined,
                                  color: Colors.black, size: 25))
                          : Container()
                      : Container(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: !isLoading
                    ? isExpired
                        ? Center(
                            child: Text("This certification link has expired."),
                          )
                        : isVerified
                            ? imageUrl.isNotEmpty
                                ? InteractiveViewer(
                                    panEnabled: true, // Allows panning
                                    boundaryMargin: EdgeInsets.all(
                                        80), // Set boundary for panning
                                    minScale: 0.5, // Minimum zoom out
                                    maxScale: 4, // Maximum zoom in
                                    child: Image.network(
                                      imageUrl,
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child; // Image has finished loading, display the image
                                        } else {
                                          // Image is still loading, display a loading indicator (GIF or any widget)
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      20.0),
                                                  child: Image.asset(
                                                    'assets/images/loading.gif', // Your loading GIF here
                                                    width:
                                                        70, // Adjust size as needed
                                                    height: 70,
                                                  ),
                                                ),
                                                Text(
                                                  "Loading image...",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                )
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            'Image not found',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text('Image not available',
                                        style: TextStyle(fontSize: 14)),
                                  )
                            : Center(
                                child: Text(
                                    "This certification is not verified.",
                                    style: TextStyle(fontSize: 14)))
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              "Verifying Certification",
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 5),
            !isLoading
                ? isVerified
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 30),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'This certification is authentic, securely protected,\n'
                              'and verified through blockchain technology.',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container()
                : Container(),
          ],
        ),
      ),
    );
  }
}
