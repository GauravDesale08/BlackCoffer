import 'dart:async';
import 'package:blackcoffer/screens/home_screen.dart';
import 'package:blackcoffer/screens/login_screen.dart';
import 'package:blackcoffer/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var auth = FirebaseAuth.instance;

  checkIsLoggedIn() async {
    auth.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        Timer(Duration(seconds: 3), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
        });
      } else {
        Timer(Duration(seconds: 3), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkIsLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.white),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Customized Logo Widget
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrimary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 80,
                color: colorPrimary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "BlackCoffer",
              style: TextStyle(
                color: colorPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
