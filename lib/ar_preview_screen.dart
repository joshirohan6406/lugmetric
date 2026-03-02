import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum WatchShape { circular, rectangularAnalog, rectangularDigital }

class ARPreviewScreen extends StatefulWidget {
  final String imagePath;
  final double scaleMMPerPixel;
  final List<Offset> wristPoints;

  const ARPreviewScreen({
    super.key,
    required this.imagePath,
    required this.scaleMMPerPixel,
    required this.wristPoints,
  });

  @override
  State<ARPreviewScreen> createState() => _ARPreviewScreenState();
}

class _ARPreviewScreenState extends State<ARPreviewScreen> {
  WatchShape shape = WatchShape.circular;
  double dialMM = 36;

  int? originalWidth;
  int? originalHeight;
  Offset? originalCenter;
  double wristWidthMM = 0;

  Offset userOffset = Offset.zero; // 🔥 DRAG OFFSET

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final left = widget.wristPoints[0];
    final right = widget.wristPoints[1];

    final pixelDistance = sqrt(
      pow(left.dx - right.dx, 2) + pow(left.dy - right.dy, 2),
    );

    wristWidthMM = pixelDistance * widget.scaleMMPerPixel * 0.90;

    setState(() {
      originalWidth = image.width;
      originalHeight = image.height;
      originalCenter = Offset(
        (left.dx + right.dx) / 2,
        (left.dy + right.dy) / 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (originalWidth == null || originalCenter == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0F14),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D7CFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenW = constraints.maxWidth;
            double screenH = constraints.maxHeight;

            double imageAspect = originalWidth! / originalHeight!;

            double displayW;
            double displayH;

            if (screenW / screenH > imageAspect) {
              displayH = screenH;
              displayW = screenH * imageAspect;
            } else {
              displayW = screenW;
              displayH = screenW / imageAspect;
            }

            double scaleFactor = displayW / originalWidth!;

            Offset displayCenter = Offset(
              originalCenter!.dx * scaleFactor + (screenW - displayW) / 2,
              originalCenter!.dy * scaleFactor + (screenH - displayH) / 2,
            );

            double dialPixels = (dialMM / widget.scaleMMPerPixel) * scaleFactor;

            double lugToLugMM = wristWidthMM * 0.72;

            double lugPixels =
                (lugToLugMM / widget.scaleMMPerPixel) * scaleFactor;

            return Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: displayW,
                    height: displayH,
                    child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                  ),
                ),

                Positioned(
                  left: displayCenter.dx - lugPixels / 2 + userOffset.dx,
                  top: displayCenter.dy - dialPixels / 2 + userOffset.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        userOffset += details.delta;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _buildWatch(
                        dialPixels,
                        lugPixels,
                        key: ValueKey("$shape-$dialMM"),
                      ),
                    ),
                  ),
                ),

                _bottomPanel(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWatch(double dialPixels, double lugPixels, {required Key key}) {
    double bezelThickness = dialPixels * 0.10;

    double caseWidth = shape == WatchShape.circular
        ? dialPixels * 1.2
        : dialPixels * 1.4;

    double caseHeight = shape == WatchShape.circular
        ? dialPixels * 1.2
        : dialPixels * 1.1;

    return Stack(
      key: key,
      alignment: Alignment.center,
      children: [
        Container(
          width: lugPixels,
          height: caseHeight * 0.35,
          decoration: BoxDecoration(
            color: const Color(0xFF2D7CFF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        Container(
          width: caseWidth,
          height: caseHeight,
          decoration: BoxDecoration(
            shape: shape == WatchShape.circular
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shape == WatchShape.circular
                ? null
                : BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),

        Container(
          width: caseWidth,
          height: caseHeight,
          decoration: BoxDecoration(
            shape: shape == WatchShape.circular
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shape == WatchShape.circular
                ? null
                : BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2D7CFF),
              width: bezelThickness,
            ),
          ),
        ),

        Container(
          width: dialPixels,
          height: shape == WatchShape.circular ? dialPixels : dialPixels * 0.85,
          decoration: BoxDecoration(
            shape: shape == WatchShape.circular
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shape == WatchShape.circular
                ? null
                : BorderRadius.circular(10),
            color: const Color(0xFF151922),
          ),
        ),
      ],
    );
  }

  Widget _bottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Color(0xFF151922),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: WatchShape.values
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text(
                          s == WatchShape.circular
                              ? "Circular"
                              : s == WatchShape.rectangularAnalog
                              ? "Rect Analog"
                              : "Rect Digital",
                        ),
                        selected: shape == s,
                        selectedColor: const Color(0xFF2D7CFF),
                        backgroundColor: const Color(0xFF0D0F14),
                        labelStyle: const TextStyle(color: Colors.white),
                        onSelected: (_) {
                          setState(() {
                            shape = s;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 14),

            Text(
              "Dial Size: ${dialMM.toStringAsFixed(0)} mm",
              style: const TextStyle(color: Color(0xFFE6E9EF)),
            ),

            Slider(
              value: dialMM,
              min: 30,
              max: 46,
              divisions: 16,
              activeColor: const Color(0xFF2D7CFF),
              onChanged: (value) {
                setState(() {
                  dialMM = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
