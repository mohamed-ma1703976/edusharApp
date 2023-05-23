import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sequence_animation/flutter_sequence_animation.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late SequenceAnimation _sequenceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _sequenceAnimation = SequenceAnimationBuilder()
        .addAnimatable(
      animatable: Tween<double>(begin: 0.0, end: 1.0),
      from: Duration.zero,
      to: Duration(milliseconds: 500),
      tag: "fade-in",
    )
        .animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _sequenceAnimation["fade-in"].value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://i.ibb.co/RN7HqQT/Edu-Share-Logo.png',
                    width: 200,
                    height: 200,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}