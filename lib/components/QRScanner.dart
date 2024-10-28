import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;
  String baseUrl = "https://nft-certification.com/event/";
  bool hasProcessed = false; // To avoid multiple navigation pop

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // QR View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ],
      ),
    );
  }

  // Callback when the QR view is created
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!hasProcessed) {
        // Ensure it only processes once
        setState(() {
          qrText = scanData.code;
        });

        if (qrText != null && qrText!.startsWith(baseUrl)) {
          // Extract the portion after the base URL
          String extractedEventId = qrText!.substring(baseUrl.length);

          hasProcessed = true; // Set this to true to avoid processing again

          // Pass the extracted event ID back and close the scanner
          Navigator.pop(context, extractedEventId);
        }
      }
    });
  }
}
