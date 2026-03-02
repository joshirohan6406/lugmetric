import 'package:flutter/material.dart';
import 'ar_preview_screen.dart';

class AnalysisScreen extends StatelessWidget {
  final double wristWidthMM;
  final double confidence;
  final String imagePath;
  final double scaleMMPerPixel;
  final List<Offset> wristPoints;

  const AnalysisScreen({
    super.key,
    required this.wristWidthMM,
    required this.confidence,
    required this.imagePath,
    required this.scaleMMPerPixel,
    required this.wristPoints,
  });

  Map<String, double> _calc() {
    double circumference = wristWidthMM * 2.7;
    double lugMax = wristWidthMM * 0.75;

    double circMin = wristWidthMM * 0.62;
    double circMax = wristWidthMM * 0.66;

    double rectAnalogMin = wristWidthMM * 0.48;
    double rectAnalogMax = wristWidthMM * 0.55;

    double rectDigitalMin = wristWidthMM * 0.55;
    double rectDigitalMax = wristWidthMM * 0.62;

    double strap = ((circMin + circMax) / 2) / 2;

    return {
      "circumference": circumference,
      "lugMax": lugMax,
      "circMin": circMin,
      "circMax": circMax,
      "rectAnalogMin": rectAnalogMin,
      "rectAnalogMax": rectAnalogMax,
      "rectDigitalMin": rectDigitalMin,
      "rectDigitalMax": rectDigitalMax,
      "strap": strap,
    };
  }

  @override
  Widget build(BuildContext context) {
    final d = _calc();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Engineering Fit Analysis",
                style: TextStyle(
                  color: Color(0xFFE6E9EF),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              _panel("Wrist Metrics", [
                _row("Width", "${wristWidthMM.toStringAsFixed(2)} mm"),
                _row(
                  "Est. Circumference",
                  "${d["circumference"]!.toStringAsFixed(0)} mm",
                ),
                _row("Max Lug-to-Lug", "${d["lugMax"]!.toStringAsFixed(0)} mm"),
                _row("Confidence", "${confidence.toStringAsFixed(1)}%"),
              ]),

              const SizedBox(height: 20),

              _panel("Circular Ideal Range", [
                _rangeGraph(
                  min: d["circMin"]!,
                  max: d["circMax"]!,
                  current: (d["circMin"]! + d["circMax"]!) / 2,
                  wrist: wristWidthMM,
                ),
                const SizedBox(height: 8),
                Text(
                  "${d["circMin"]!.toStringAsFixed(0)} – ${d["circMax"]!.toStringAsFixed(0)} mm",
                  style: const TextStyle(color: Color(0xFFE6E9EF)),
                ),
              ]),

              const SizedBox(height: 20),

              _panel("Rectangular Analog", [
                Text(
                  "${d["rectAnalogMin"]!.toStringAsFixed(0)} – ${d["rectAnalogMax"]!.toStringAsFixed(0)} mm",
                  style: const TextStyle(color: Color(0xFFE6E9EF)),
                ),
              ]),

              const SizedBox(height: 20),

              _panel("Rectangular Digital", [
                Text(
                  "${d["rectDigitalMin"]!.toStringAsFixed(0)} – ${d["rectDigitalMax"]!.toStringAsFixed(0)} mm",
                  style: const TextStyle(color: Color(0xFFE6E9EF)),
                ),
              ]),

              const SizedBox(height: 20),

              _panel("Strap Recommendation", [
                _row(
                  "Recommended Strap",
                  "${d["strap"]!.toStringAsFixed(0)} mm",
                ),
                const Text(
                  "Slim to medium case thickness advised.",
                  style: TextStyle(color: Color(0xFF9AA4B2)),
                ),
              ]),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ARPreviewScreen(
                          imagePath: imagePath,
                          scaleMMPerPixel: scaleMMPerPixel,
                          wristPoints: wristPoints,
                        ),
                      ),
                    );
                  },
                  child: const Text("VIEW IN AR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2D7CFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Color(0xFF9AA4B2))),
          Text(v, style: const TextStyle(color: Color(0xFFE6E9EF))),
        ],
      ),
    );
  }

  Widget _rangeGraph({
    required double min,
    required double max,
    required double current,
    required double wrist,
  }) {
    double percentMin = min / wrist;
    double percentMax = max / wrist;

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Stack(
          children: [
            Container(
              height: 8,
              width: width,
              decoration: BoxDecoration(
                color: const Color(0xFF222833),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              left: width * percentMin,
              child: Container(
                height: 8,
                width: width * (percentMax - percentMin),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7CFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
