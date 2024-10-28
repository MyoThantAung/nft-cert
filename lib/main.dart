import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nft_cert/firebase_options.dart';
import 'package:nft_cert/user/login_page.dart';
import 'package:nft_cert/user/shareNFTPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());

  // Set status bar background color to white and icons to black
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // Status bar background color
    statusBarIconBrightness: Brightness.dark, // Status bar icon color (black)
    statusBarBrightness:
        Brightness.light, // For iOS, set the status bar color to white
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

/*

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}*/

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    String initialRoute = Uri.base.path;
    if (initialRoute == null || initialRoute.isEmpty) {
      initialRoute = '/';
    }

    print('Initial Route: $initialRoute');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Uri uri = Uri.parse(settings.name ?? '/');

    // Debugging output
    print('Settings Name: ${settings.name}');
    print('Parsed URI Path: ${uri.path}');
    print('Path Segments: ${uri.pathSegments}');

    // Handle '/verified/{id}' route
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'verified') {
      String tokenId = uri.pathSegments[1]; // Extract the tokenId
      return MaterialPageRoute(
          builder: (_) => NFTCertificationScreen(
                tokenId: tokenId,
                share: false,
              ));
    }

    // Handle '/event/{id}' route
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'event') {
      String tokenId = uri.pathSegments[1]; // Extract the tokenId
      return MaterialPageRoute(builder: (_) => LoginScreen());
    }

    // Handle home route
    if (uri.path == '/' || uri.path == '') {
      return MaterialPageRoute(builder: (_) => LoginScreen());
    }

    // If no matching route, show UnknownPage
    return MaterialPageRoute(builder: (_) => UnknownPage());
  }
}

class UnknownPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unknown Page'),
      ),
      body: Center(
        child: Text('404 - Page Not Found'),
      ),
    );
  }
}
