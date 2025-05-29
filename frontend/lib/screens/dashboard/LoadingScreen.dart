import 'package:flutter/material.dart';
import 'dart:async';
import '../auth/login_screen.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double progress = 0.0;

  final Color backgroundColor = Color(
    0xFFFDF1E7,
  ); // Login page background color
  final Color progressColor = Color(0xFFFF9800); // Orange button color

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.bounceOut);
    _controller.forward();

    Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        progress += 0.05;
        if (progress >= 1.0) {
          timer.cancel();
          navigateToLogin();
        }
      });
    });
  }

  void navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildProgressBar() {
    return Container(
      height: 6,
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8 * progress,
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget buildLogoSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _animation,
          child: Icon(Icons.restaurant, color: progressColor, size: 100),
        ),
        SizedBox(height: 20),
        Text(
          "FoodFlowSL",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildLogoSection(),
            SizedBox(height: 50),
            buildProgressBar(),
          ],
        ),
      ),
    );
  }
}
