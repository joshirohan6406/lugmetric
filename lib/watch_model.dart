enum WatchShape { circular, rectangularAnalog, rectangularDigital }

class WatchModel {
  final WatchShape shape;
  final double dialMM;

  WatchModel({required this.shape, required this.dialMM});

  // Bezel thickness ratio
  double get bezelRatio {
    switch (shape) {
      case WatchShape.circular:
        return 0.12;
      case WatchShape.rectangularAnalog:
        return 0.10;
      case WatchShape.rectangularDigital:
        return 0.18;
    }
  }

  // Lug-to-lug multiplier
  double get lugMultiplier {
    switch (shape) {
      case WatchShape.circular:
        return 1.20;
      case WatchShape.rectangularAnalog:
        return 1.15;
      case WatchShape.rectangularDigital:
        return 1.25;
    }
  }

  // Aspect ratio for rectangular
  double get aspectRatio {
    switch (shape) {
      case WatchShape.circular:
        return 1.0;
      case WatchShape.rectangularAnalog:
        return 1.25; // taller
      case WatchShape.rectangularDigital:
        return 0.85; // wider
    }
  }
}
