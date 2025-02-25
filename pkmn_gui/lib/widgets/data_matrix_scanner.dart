import 'package:flutter/material.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

class DataMatrixScanner extends StatelessWidget {
  final Function(String) onCodeScanned;
  const DataMatrixScanner({super.key, required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: AiBarcodeScanner(
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
          onDetect: (BarcodeCapture capture) {
            if (capture.barcodes.isNotEmpty) {
              final barcode = capture.barcodes.first;
              final scannedValue = barcode.rawValue;
              if (scannedValue != null) {
                onCodeScanned(scannedValue);
              }
            }
          },
        ),
      ),
    );
  }
}
