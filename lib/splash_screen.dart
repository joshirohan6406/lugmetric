import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textOpacity;
  late Animation<double> _lineProgress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _lineProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double lineWidth = 200 * _lineProgress.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _textOpacity.value,
                  child: const Text(
                    "LUGMETRIC",
                    style: TextStyle(
                      color: Color(0xFFE6E9EF),
                      fontSize: 26,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Column(
                  children: [
                    Container(
                      width: lineWidth,
                      height: 2,
                      color: const Color(0xFF2D7CFF),
                    ),

                    if (_lineProgress.value > 0.95)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 2,
                            height: 14,
                            color: const Color(0xFF2D7CFF),
                          ),
                          SizedBox(width: lineWidth - 4),
                          Container(
                            width: 2,
                            height: 14,
                            color: const Color(0xFF2D7CFF),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
