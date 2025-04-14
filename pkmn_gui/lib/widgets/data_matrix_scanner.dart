import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants.dart';

enum ScannerFormat { dataMatrix, qrCode }

BarcodeFormat _mapScannerFormat(ScannerFormat sf) {
  switch (sf) {
    case ScannerFormat.dataMatrix:
      return BarcodeFormat.dataMatrix;
    case ScannerFormat.qrCode:
      return BarcodeFormat.qrCode;
  }
}

class DataMatrixScanner extends StatefulWidget {
  final Function(String) onCodeScanned;
  final String sheetTitle;
  final ScannerFormat scannerFormat;

  const DataMatrixScanner({
    super.key,
    required this.onCodeScanned,
    required this.sheetTitle,
    this.scannerFormat = ScannerFormat.dataMatrix,
  });

  @override
  State<DataMatrixScanner> createState() => _DataMatrixScannerState();
}

class _DataMatrixScannerState extends State<DataMatrixScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.secondaryRed,
                  width: UIConstants.borderWidth3,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(
                      UIConstants.borderRadius8,
                    ),
                    border: Border.all(
                      color: AppColors.secondaryRed,
                      width: UIConstants.borderWidth2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF992109),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.sheetTitle,
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      color: AppColors.white,
                      shadows: AppShadows.textShadow,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.unrestricted,
                    detectionTimeoutMs: 100,
                    formats: [_mapScannerFormat(widget.scannerFormat)],
                  ),
                  onDetect: (BarcodeCapture capture) {
                    if (capture.barcodes.isNotEmpty) {
                      final scannedValue = capture.barcodes.first.rawValue;
                      if (scannedValue != null) {
                        widget.onCodeScanned(scannedValue);
                      }
                    }
                  },
                ),
                // Scanner overlay
                Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE3350D).withOpacity(0.8),
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            // Scanning line
                            Positioned(
                              top: 280 * _animation.value - 2,
                              child: Container(
                                width: 280,
                                height: 4,
                                color: const Color(0xFF62B1F6).withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
