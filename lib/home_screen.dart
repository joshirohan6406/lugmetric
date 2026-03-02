import 'package:flutter/material.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "LUGMETRIC",
              style: TextStyle(
                color: Color(0xFFE6E9EF),
                fontSize: 26,
                letterSpacing: 6,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Precision Watch Fit",
              style: TextStyle(color: Color(0xFF9AA4B2), fontSize: 14),
            ),

            const SizedBox(height: 60),

            SizedBox(
              width: 240,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                },
                child: const Text(
                  "START MEASUREMENT",
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
