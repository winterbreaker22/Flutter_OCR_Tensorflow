# ocr_tf

A Flutter project for extracting specific information from photo.

# Guide

- Update AndroidManifest.xml

    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>


- android/build.gradle 

    - Need to add below code

      buildscript {
          repositories {
              google()
              mavenCentral()
          }
          dependencies {
              classpath 'com.android.tools.build:gradle:8.0.2' 
              classpath 'com.google.gms:google-services:4.4.2'
          }
      }


- android/app/proguard-rules.pro 

    - Content of this file

      # Prevent R8 from removing ML Kit dependencies
      -keep class com.google.mlkit.** { *; }
      -keep class com.google.android.gms.** { *; }

      # Prevent R8 from removing TensorFlow Lite classes
      -keep class org.tensorflow.** { *; }

      # Prevent R8 from obfuscating some classes required by ML Kit
      -dontwarn com.google.mlkit.**

      # Keep annotations
      -keepattributes *Annotation*

      # Prevent R8 from removing resources
      -keepclassmembers class ** {
          public static final int *;
      }

      # Prevent warnings about missing classes
      -dontwarn com.google.mlkit.vision.**
      -dontwarn org.tensorflow.lite.**
      

- android/app/build.gradle

    - Need to update or add below part

      minSdk = 26

      buildTypes {
          release {
              minifyEnabled true  // Enable ProGuard
              shrinkResources true
              proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
          }
      }

      dependencies {
        implementation 'org.tensorflow:tensorflow-lite:2.15.0' 
        implementation 'org.tensorflow:tensorflow-lite-select-tf-ops:2.15.0'
      }

      apply plugin: 'com.google.gms.google-services'


- Gradle Sync in Android Studio    

- Need google-services.json file from firebase to android/app

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
    