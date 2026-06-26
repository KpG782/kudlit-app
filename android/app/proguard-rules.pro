# Keep rules for when R8 / minify is enabled (currently OFF in build.gradle.kts).
# These protect the on-device ML native bridges from being stripped/renamed.
# Verify an AAB end-to-end after enabling isMinifyEnabled/isShrinkResources.

# TensorFlow Lite (used by ultralytics_yolo / tflite)
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Ultralytics YOLO
-keep class com.ultralytics.** { *; }
-dontwarn com.ultralytics.**

# MediaPipe / flutter_gemma on-device LLM
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Flutter embedding & plugins
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
