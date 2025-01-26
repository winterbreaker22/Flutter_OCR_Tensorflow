import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../services/image_processor.dart';

class CameraViewController extends GetxController {
  late CameraController cameraController;
  RxBool isInitialized = false.obs;
  RxString capturedImagePath = ''.obs;
  Rx<Uint8List?> processedImage = Rx<Uint8List?>(null);

  final int targetWidth = 512;
  final int targetHeight = 512;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.high);
    await cameraController.initialize();
    isInitialized.value = true;
  }

  Future<void> capturePhoto() async {
    final image = await cameraController.takePicture();
    capturedImagePath.value = image.path;

    // Preprocess the captured image
    processedImage.value = await preprocessImage(image.path, targetWidth, targetHeight);
  }

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }
}
