# ocr_tf

A Flutter project for extracting specific information from photo.

# Guide

- Update AndroidManifest.xml

    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>

- android/app/build.gradle

    dependencies {
      implementation 'org.tensorflow:tensorflow-lite:2.15.0' 
      implementation 'org.tensorflow:tensorflow-lite-select-tf-ops:2.15.0'
    }

- Gradle Sync in Android Studio    

- Assets

    assets/label_map.pbtxt
    assets/model.tflite
    android/app/src/main/assets/model.tflite

- Image Controller
 
    - Load Model
    - Load LabelMapData, and parse
    - Preprocess Image
      Resizing, Padding with keeping aspect ratio
    - Convert resized image to inputTensor
    - Run Model
    - Output handling
      getting boxes data, find highest score box for each field
    - Adjusting boxes to original size

- android\app\src\main\kotlin\com\example\ocr_tf\MainActivity.kt

    Consult this file
    Loading and running model are done here and communicate with flutter by using MethodChannel platform (bridge)
    