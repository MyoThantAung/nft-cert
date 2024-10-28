import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/admin/request_detail.dart';
import 'package:nft_cert/components/event_card.dart';
import 'package:intl/intl.dart';

class RequestDataScreen extends StatelessWidget {
  final String orgId;
  final String cereId;
  final String eventName;
  final String organizationName;
  final bool verified;
  final bool available;

  RequestDataScreen({
    required this.orgId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
  });

  Stream<List<Map<String, dynamic>>> getRequests() {
    final firestore = FirebaseFirestore.instance;

    // First, query the certification_request_form collection
    Stream<QuerySnapshot> certificationRequestStream = firestore
        .collection('certification_request_form')
        .where('cereId', isEqualTo: cereId)
        .orderBy('createDate')
        .snapshots();

    // Combine with the second collection
    return certificationRequestStream.asyncMap((certificationRequests) async {
      List<Map<String, dynamic>> result = [];

      for (var request in certificationRequests.docs) {
        final cereId = request['cereId'];
        final userId = request['userId'];
        final orgId = request['orgId'];

        // Check if there is a matching document in the minted_certification collection
        QuerySnapshot mintedCert = await firestore
            .collection('minted_certification')
            .where('cereId', isEqualTo: cereId)
            .where('userId', isEqualTo: userId)
            .where('orgId', isEqualTo: orgId)
            .get();

        // Fetch the user email from the 'users' collection using the userId
        DocumentSnapshot userDoc =
            await firestore.collection('users').doc(userId).get();

        String userEmail =
            userDoc.exists ? userDoc['email'] ?? 'Unknown' : 'Unknown';

        // Create a map with request data
        Map<String, dynamic> requestData = {
          'request': request.data(),
          'docId': request.id,
          'verified': request['verified'] ?? false,
          'mintedCert':
              mintedCert.docs.isNotEmpty ? mintedCert.docs.first.data() : null,
          'userEmail': userEmail, // Add user email to the result
        };

        // Add requestData to result
        result.add(requestData);
      }

      return result;
    });
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Certification Event',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Header Row for "Date" and "ID"
              Padding(
                padding: const EdgeInsets.only(
                  left: 30,
                  right: 30,
                  top: 5,
                  bottom: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Email',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 0,
                    bottom: 0,
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print(snapshot.error);
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No Requests Found'));
                      }

                      var docs = snapshot.data!;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index];
                          var requestData =
                              data['request'] as Map<String, dynamic>;
                          String docId = data['docId'];
                          String userEmail = data['userEmail'];
                          bool verified = data['verified'] ?? false;
                          var mintedCert = data['mintedCert'];

                          bool isMinted = false;
                          bool isTranferred = false;
                          String tokenId = "";

                          if (mintedCert != null) {
                            isMinted = true;
                            isTranferred = mintedCert["isTransferred"];
                            tokenId = mintedCert["nftTokenId"];
                          }

                          // Assuming 'createDate' is of type Timestamp
                          Timestamp timestamp = requestData['createDate'];
                          DateTime dateTime = timestamp
                              .toDate(); // Convert Timestamp to DateTime
                          String date =
                              DateFormat('dd/MM/yyyy').format(dateTime);

                          // Determine color based on verification status
                          Color cardColor = verified
                              ? isMinted
                                  ? isTranferred
                                      ? Colors.cyan
                                      : Colors.lime
                                  : Colors.green[200]!
                              : Colors.grey[300]!;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RequestDetailScreen(
                                    requestId: docId,
                                    orgId: orgId,
                                    userId: requestData['userId'],
                                    cereId: cereId,
                                    eventName: eventName,
                                    organizationName: organizationName,
                                    verified: verified,
                                    available: available,
                                    isTransferred: isTranferred,
                                    tokenId: tokenId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(date), // Show the date
                                    Text(userEmail),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
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
