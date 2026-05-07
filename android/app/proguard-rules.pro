# ─────────────────────────────────────────────────────────────────
#  Flutter / Dart engine — NEVER strip these
# ─────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# Keep Dart entry points
-keepclassmembers class * {
    @io.flutter.embedding.engine.plugins.FlutterPlugin *;
}

# ─────────────────────────────────────────────────────────────────
#  Kotlin runtime & coroutines
# ─────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Lazy { *; }

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ─────────────────────────────────────────────────────────────────
#  Firebase — Core, Auth, Firestore, Messaging, Analytics,
#             Crashlytics, RemoteConfig, AppCheck
# ─────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# App Check
-keep class com.google.firebase.appcheck.** { *; }
-dontwarn com.google.firebase.appcheck.**

# ─────────────────────────────────────────────────────────────────
#  Google Sign-In
# ─────────────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.api.** { *; }

# ─────────────────────────────────────────────────────────────────
#  Hive (local storage / offline cache)
# ─────────────────────────────────────────────────────────────────
-keep class com.hive.** { *; }
-keep class hive.** { *; }
# Keep all Hive TypeAdapters generated for the app
-keep class ** implements com.hivedb.hive.TypeAdapter { *; }

# ─────────────────────────────────────────────────────────────────
#  flutter_local_notifications
# ─────────────────────────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Scheduled / exact alarms receiver
-keep class * extends android.content.BroadcastReceiver { *; }

# ─────────────────────────────────────────────────────────────────
#  flutter_secure_storage  (uses EncryptedSharedPreferences)
# ─────────────────────────────────────────────────────────────────
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# ─────────────────────────────────────────────────────────────────
#  Google Play Core (split install / in-app updates used internally
#  by some Firebase / Flutter plugins)
# ─────────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ─────────────────────────────────────────────────────────────────
#  AndroidX
# ─────────────────────────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keepattributes *Annotation*

# ─────────────────────────────────────────────────────────────────
#  Multidex
# ─────────────────────────────────────────────────────────────────
-keep class androidx.multidex.** { *; }

# ─────────────────────────────────────────────────────────────────
#  Reflection / serialisation
# ─────────────────────────────────────────────────────────────────
# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ─────────────────────────────────────────────────────────────────
#  Suppress warnings for optional deps not always present
# ─────────────────────────────────────────────────────────────────
-dontwarn sun.misc.**
-dontwarn java.awt.**
-dontwarn javax.annotation.**
