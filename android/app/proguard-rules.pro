# Flutter-specific ProGuard rules

# Keep Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Fix R8 missing class errors for Google Play Core (often used by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

