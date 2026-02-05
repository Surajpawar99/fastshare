import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  late final MobileScannerController _controller;
  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with specific settings for QR codes
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        handleIncomingLink(barcode.rawValue!);
        break;
      }
    }
  }

  void handleIncomingLink(String qrValue) {
    Navigator.pop(context, qrValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Layer
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Camera Error: ${error.errorCode}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Check app permissions.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Overlay Layer (Dimmed Background + Cutout)
          CustomPaint(
            painter: _ScannerOverlayPainter(
              borderColor: theme.colorScheme.primary,
              borderRadius: 24,
              borderLength: 30,
              borderWidth: 6,
              cutoutSize: 280,
            ),
            child: Container(),
          ),

          // 3. UI Layer (AppBar & Controls)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Torch Button
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Scan Sender QR Code",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Spacing from bottom
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR SCANNER OVERLAY ---
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutoutSize;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutoutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double halfCutout = cutoutSize / 2;

    // 1. Draw Semi-Transparent Background
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create a path that covers the whole screen but excludes the rounded rect in the middle
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: cutoutSize,
            height: cutoutSize,
          ),
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Draw Corner Borders
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Draw 4 Corners
    _drawCorner(
      canvas,
      borderPaint,
      centerX - halfCutout,
      centerY - halfCutout,
      0,
    ); // Top Left
    _drawCorner(
      canvas,
      borderPaint,
      centerX + halfCutout,
      centerY - halfCutout,
      90,
    ); // Top Right
    _drawCorner(
      canvas,
      borderPaint,
      centerX + halfCutout,
      centerY + halfCutout,
      180,
    ); // Bottom Right
    _drawCorner(
      canvas,
      borderPaint,
      centerX - halfCutout,
      centerY + halfCutout,
      270,
    ); // Bottom Left
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double angleDegrees,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angleDegrees * 3.14159 / 180);

    final Path path = Path()
      ..moveTo(0, borderLength)
      ..lineTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..lineTo(borderLength, 0);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
