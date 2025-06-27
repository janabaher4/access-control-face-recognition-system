import 'package:face/login.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
class SplashScreen extends StatelessWidget {
  final CameraDescription camera;

  const SplashScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 14, 71),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
