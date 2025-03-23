import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // replaced ai_barcode_scanner

class DataMatrixScanner extends StatelessWidget {
  final Function(String) onCodeScanned;
  final String sheetTitle;
  const DataMatrixScanner({
    super.key,
    required this.onCodeScanned,
    required this.sheetTitle,
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
                detectionTimeoutMs: 100, // Lower timeout may speed up scanning
                // scanWindow: Rect.fromLTWH(100, 100, 200, 200), // optional: restrict scanning area
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
