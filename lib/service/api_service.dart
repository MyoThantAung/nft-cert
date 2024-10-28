import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl =
      'https://api.nft-certification.com'; // Your API base URL
  final String apiKey = 'gdtyhsg4uy2twg1f2vwg2f'; // Your API key

  // Function to create a new wallet and return wallet info
  Future<Map<String, String>> createWallet() async {
    final url = Uri.parse('$baseUrl/create-wallet');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    try {
      // Making the GET request to the create-wallet endpoint
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);

        // Extract wallet address and private key
        final walletAddress = jsonResponse['walletAddress'];
        final privateKey = jsonResponse['privateKey'];

        // Return a map containing the wallet info
        return {
          'walletAddress': walletAddress,
          'privateKey': privateKey,
        };
      } else {
        // Handle error response
        print('Failed to create wallet. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to mint an NFT and return the transaction hash
  Future<Map<String, dynamic>> mintNFT(
    String userWallet,
    String userId,
    String eventId,
    String data,
    String image,
  ) async {
    final url = Uri.parse('$baseUrl/mint-nft');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // JSON body for the POST request
    final body = jsonEncode({
      'userWallet': userWallet,
      'userId': userId,
      'eventId': eventId,
      'data': data,
      'image': image,
    });

    try {
      // Making the POST request to mint an NFT
      final response = await http.post(url, headers: headers, body: body);

      // Parse the response JSON
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse; // Return the response data (transaction details)
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to set the event max limit
  Future<Map<String, dynamic>> setEventMaxLimit(
      String eventId, int maxLimit) async {
    final url = Uri.parse('$baseUrl/set-event-max-limit');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // JSON body for the POST request
    final body = jsonEncode({
      'eventId': eventId,
      'maxLimit': maxLimit,
    });

    try {
      // Making the POST request to set event max limit
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print(
            'Failed to set event max limit. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to transfer an NFT
  Future<Map<String, dynamic>> transferNFT(
    String toAddress,
    String tokenId,
  ) async {
    final url = Uri.parse('$baseUrl/transfer-nft');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // JSON body for the POST request
    final body = jsonEncode({
      'toAddress': toAddress,
      'tokenId': tokenId,
    });

    try {
      // Making the POST request to transfer an NFT
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print('Failed to transfer NFT. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to fetch NFT data (data and image)
  Future<Map<String, dynamic>> getNFTData(String tokenId) async {
    final url = Uri.parse('$baseUrl/nft-data/$tokenId');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    try {
      // Making the GET request to fetch NFT data
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print('Failed to fetch NFT data. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to fetch token information (to, userWallet, userId, eventId)
  Future<Map<String, dynamic>> getTokenInfo(String tokenId) async {
    final url = Uri.parse('$baseUrl/token-info/$tokenId');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    try {
      // Making the GET request to fetch token info
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print(
            'Failed to fetch token info. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }

  // Function to fetch NFTs status by wallet address
  Future<Map<String, dynamic>> getNFTStatus(String walletAddress) async {
    final url = Uri.parse('$baseUrl/get-nfts-status/$walletAddress');

    // Headers including the API key
    final headers = {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    try {
      // Making the GET request to fetch NFTs status
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print(
            'Failed to fetch NFTs status. Status code: ${response.statusCode}');
        print('Error message: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error occurred: $e');
      return {};
    }
  }
}
