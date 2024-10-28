import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/components/nft_card.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:nft_cert/user/event_list.dart';
import 'package:nft_cert/user/shareNFTPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class homeScreen extends StatefulWidget {
  @override
  State<homeScreen> createState() => _main_pageState();
}

class _main_pageState extends State<homeScreen> {
  final PageController _pageController = PageController();
  bool isLoading = true;
  ApiService apiService = ApiService();
  List<dynamic> nfts = []; // List to hold the NFTs

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
    _fetchNFTStatus();
  }

  // Function to fetch NFT status
  Future<void> _fetchNFTStatus() async {
    await getUserInfo();
    print(walletAddress);
    final result = await apiService.getNFTStatus(walletAddress!);
    setState(() {
      if (result.isNotEmpty && result['nfts'] != null) {
        nfts = result['nfts']; // Store the NFTs in the state
        print("NFTs Exist : " + nfts.length.toString());
      }
      isLoading = false; // Set loading to false when data is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  /*
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 0, bottom: 0, top: 0, right: 10),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: isLoading
                  ? Center(
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
                          ), // Spinner
                          SizedBox(
                              height: 12), // Spacing between spinner and text
                          Text(
                            "Loading NFTs...",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : nfts.isEmpty
                      ? Center(
                          child: Text(
                              "No NFTs found")) // Show when there are no NFTs
                      : Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: nfts.length,
                            itemBuilder: (context, index) {
                              final nft = nfts[index];
                              return NFTCardWidget(
                                imageUrl:
                                    "https://blue-tricky-wombat-943.mypinata.cloud/ipfs/" +
                                        nft['image'], // Base64 image
                                tokenId: nft['tokenId'],
                              );
                            },
                          ),
                        ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController, // PageController
                    count: nfts.length,
                    effect: WormEffect(
                      dotHeight: 8.0,
                      dotWidth: 8.0,
                      activeDotColor: Colors.blueAccent,
                      dotColor: Colors.blueGrey,
                    ),
                  ),
                ],
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
                  MaterialPageRoute(builder: (context) => EventList()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
