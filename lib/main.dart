import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/camera_screen.dart';
import 'views/result_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Document Detection',
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => CameraScreen()),
        GetPage(name: '/results', page: () => ResultScreen()),
      ],
    );
  }
}
