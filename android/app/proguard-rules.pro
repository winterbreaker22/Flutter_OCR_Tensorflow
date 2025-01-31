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
