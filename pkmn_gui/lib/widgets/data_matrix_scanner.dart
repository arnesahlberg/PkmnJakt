import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // replaced ai_barcode_scanner

// New custom enum to select scanning format
enum ScannerFormat { dataMatrix, qrCode }

// Mapping helper function
BarcodeFormat _mapScannerFormat(ScannerFormat sf) {
  switch (sf) {
    case ScannerFormat.dataMatrix:
      return BarcodeFormat.dataMatrix;
    case ScannerFormat.qrCode:
      return BarcodeFormat.qrCode;
  }
}

class DataMatrixScanner extends StatelessWidget {
  final Function(String) onCodeScanned;
  final String sheetTitle;
  final ScannerFormat scannerFormat; // changed from list to singular

  const DataMatrixScanner({
    super.key,
    required this.onCodeScanned,
    required this.sheetTitle,
    this.scannerFormat = ScannerFormat.dataMatrix, // default value
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), //  margin
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sheetTitle,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium, // smaller text style
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.unrestricted,
                detectionTimeoutMs: 100, // lower timeout may speed up scanning?
                formats: [
                  _mapScannerFormat(scannerFormat),
                ], // wrap single type in list
              ),
              onDetect: (BarcodeCapture capture) {
                if (capture.barcodes.isNotEmpty) {
                  final scannedValue = capture.barcodes.first.rawValue;
                  if (scannedValue != null) {
                    onCodeScanned(scannedValue);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
