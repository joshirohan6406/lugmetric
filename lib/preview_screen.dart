import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'analysis_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  int? imageWidth;
  int? imageHeight;

  final TransformationController _transformController =
      TransformationController();

  // Card calibration
  List<Offset> displayCardPoints = [];
  List<Offset> realCardPoints = [];

  // Wrist measurement
  List<Offset> displayWristPoints = [];
  List<Offset> realWristPoints = [];

  bool calibrationLocked = false;

  double? scaleMMPerPixel;
  double? confidence;
  double? wristWidthMM;

  static const double realCardWidthMM = 85.6;
  static const double realCardHeightMM = 53.98;
  static const double expectedRatio = realCardWidthMM / realCardHeightMM;

  @override
  void initState() {
    super.initState();
    _loadImageInfo();
  }

  Future<void> _loadImageInfo() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    setState(() {
      imageWidth = image.width;
      imageHeight = image.height;
    });
  }

  void _handleTap(Offset localPosition, Size drawnSize) {
    if (imageWidth == null || imageHeight == null) return;

    final Matrix4 matrix = _transformController.value;
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);

    final vm.Vector3 vector = vm.Vector3(localPosition.dx, localPosition.dy, 0);
    final vm.Vector3 untransformed = inverseMatrix.transform3(vector);

    final displayX = untransformed.x;
    final displayY = untransformed.y;

    final scaleX = imageWidth! / drawnSize.width;
    final scaleY = imageHeight! / drawnSize.height;

    final realX = displayX * scaleX;
    final realY = displayY * scaleY;

    setState(() {
      if (!calibrationLocked) {
        if (realCardPoints.length >= 4) return;

        displayCardPoints.add(Offset(displayX, displayY));
        realCardPoints.add(Offset(realX, realY));

        if (realCardPoints.length == 4) {
          _processCardGeometry();
        }
      } else {
        if (realWristPoints.length >= 2) return;

        displayWristPoints.add(Offset(displayX, displayY));
        realWristPoints.add(Offset(realX, realY));

        if (realWristPoints.length == 2) {
          _processWristMeasurement();
        }
      }
    });
  }

  void _processCardGeometry() {
    final ordered = _orderPoints(realCardPoints);

    final tl = ordered[0];
    final tr = ordered[1];
    final br = ordered[2];
    final bl = ordered[3];

    final topWidth = _distance(tl, tr);
    final bottomWidth = _distance(bl, br);
    final leftHeight = _distance(tl, bl);
    final rightHeight = _distance(tr, br);

    final correctedWidth = sqrt(topWidth * bottomWidth);
    final correctedHeight = sqrt(leftHeight * rightHeight);

    final measuredRatio = correctedWidth / correctedHeight;
    final ratioError = (measuredRatio - expectedRatio).abs();

    final topBottomDiff =
        (topWidth - bottomWidth).abs() / max(topWidth, bottomWidth);

    final leftRightDiff =
        (leftHeight - rightHeight).abs() / max(leftHeight, rightHeight);

    scaleMMPerPixel = realCardWidthMM / correctedWidth;

    double ratioScore = max(0, 1 - (ratioError / 0.45));
    double perspectivePenalty = (topBottomDiff + leftRightDiff) / 2;
    double perspectiveScore = max(0, 1 - (perspectivePenalty / 0.6));

    confidence = 100 * (0.85 * ratioScore + 0.15 * perspectiveScore);

    setState(() {});
  }

  void _processWristMeasurement() {
    final p1 = realWristPoints[0];
    final p2 = realWristPoints[1];

    final pixelDistance = _distance(p1, p2);

    double rawWidth = pixelDistance * scaleMMPerPixel!;

    wristWidthMM = rawWidth * 0.90;

    setState(() {});
  }

  List<Offset> _orderPoints(List<Offset> pts) {
    final points = List<Offset>.from(pts);
    points.sort((a, b) => a.dy.compareTo(b.dy));

    final topTwo = points.sublist(0, 2);
    final bottomTwo = points.sublist(2, 4);

    topTwo.sort((a, b) => a.dx.compareTo(b.dx));
    bottomTwo.sort((a, b) => a.dx.compareTo(b.dx));

    return [topTwo[0], topTwo[1], bottomTwo[1], bottomTwo[0]];
  }

  double _distance(Offset a, Offset b) {
    return sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));
  }

  List<Widget> _buildMarkers(List<Offset> points, Color color) {
    return points.map((p) {
      return Positioned(
        left: p.dx - 6,
        top: p.dy - 6,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: imageWidth == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D7CFF)),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final displayHeight = constraints.maxHeight * 0.75;

                final imageAspect = imageWidth! / imageHeight!;
                final containerAspect = constraints.maxWidth / displayHeight;

                double drawnWidth;
                double drawnHeight;

                if (imageAspect > containerAspect) {
                  drawnWidth = constraints.maxWidth;
                  drawnHeight = constraints.maxWidth / imageAspect;
                } else {
                  drawnHeight = displayHeight;
                  drawnWidth = displayHeight * imageAspect;
                }

                final drawnSize = Size(drawnWidth, drawnHeight);

                return Column(
                  children: [
                    SizedBox(
                      height: displayHeight,
                      child: GestureDetector(
                        onTapDown: (details) {
                          _handleTap(details.localPosition, drawnSize);
                        },
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 1,
                          maxScale: 6,
                          child: Stack(
                            children: [
                              Image.file(
                                File(widget.imagePath),
                                width: drawnWidth,
                                height: drawnHeight,
                                fit: BoxFit.contain,
                              ),
                              ..._buildMarkers(
                                displayCardPoints,
                                const Color(0xFF2D7CFF),
                              ),
                              ..._buildMarkers(
                                displayWristPoints,
                                const Color(0xFF5CA9FF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ---- CARD CALIBRATION ----
                    if (!calibrationLocked) ...[
                      const Text(
                        "Tap 4 card corners",
                        style: TextStyle(color: Color(0xFF9AA4B2)),
                      ),

                      const SizedBox(height: 8),

                      if (confidence != null)
                        Text(
                          "Confidence: ${confidence!.toStringAsFixed(1)}%",
                          style: const TextStyle(color: Color(0xFF2D7CFF)),
                        ),

                      const SizedBox(height: 12),

                      if (realCardPoints.length == 4)
                        ElevatedButton(
                          onPressed: (confidence ?? 0) >= 50
                              ? () {
                                  setState(() {
                                    calibrationLocked = true;
                                  });
                                }
                              : null,
                          child: const Text("LOCK CALIBRATION"),
                        ),

                      TextButton(
                        onPressed: () {
                          setState(() {
                            displayCardPoints.clear();
                            realCardPoints.clear();
                            confidence = null;
                          });
                        },
                        child: const Text(
                          "RESET",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],

                    // ---- WRIST MEASUREMENT ----
                    if (calibrationLocked) ...[
                      const Text(
                        "Tap wrist edges",
                        style: TextStyle(color: Color(0xFF9AA4B2)),
                      ),

                      if (wristWidthMM != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Wrist Width: ${wristWidthMM!.toStringAsFixed(2)} mm",
                          style: const TextStyle(
                            color: Color(0xFFE6E9EF),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnalysisScreen(
                                  wristWidthMM: wristWidthMM!,
                                  confidence: confidence ?? 0,
                                  imagePath: widget.imagePath,
                                  scaleMMPerPixel: scaleMMPerPixel!,
                                  wristPoints: realWristPoints,
                                ),
                              ),
                            );
                          },
                          child: const Text("CONTINUE"),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
    );
  }
}
