# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager / Google Mobile Ads
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }

# Ignore missing play core classes
-dontwarn com.google.android.play.core.**
