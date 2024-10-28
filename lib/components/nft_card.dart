import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nft_cert/user/shareNFTPage.dart';

class NFTCardWidget extends StatelessWidget {
  final String imageUrl;
  final String tokenId;

  const NFTCardWidget({
    Key? key,
    required this.imageUrl,
    required this.tokenId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return nftCard(imageUrl, tokenId, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NFTCertificationScreen(
            tokenId: tokenId,
            share: true,
          ), // Assuming you have a share page
        ),
      );
    });
  }
}

Widget nftCard(String imageUrl, String tokenId, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          width: 400.0,
          height: 600.0,
          decoration: BoxDecoration(
            color: Colors.grey[200], // Fallback color
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  ),
                ),
              ),
              /*
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  color: Colors.black54,
                  child: Text(
                    'Token ID: $tokenId',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              */
            ],
          ),
        ),
      ),
    ),
  );
}
