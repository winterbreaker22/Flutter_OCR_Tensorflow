import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/image_controller.dart';
import 'screens/camera_screen.dart';
import 'screens/result_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the GetX Controller
    Get.put(ImageController());

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Image Processing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const CameraScreen()),
        GetPage(name: '/result', page: () => const ResultScreen()),
      ],
    );
  }
}
