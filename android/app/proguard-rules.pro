#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent obfuscating generic types
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# R8/ProGuard rules for Flutter plugins
-keep class com.dexterous.** { *; } # permission_handler
-keep class net.touchcapture.** { *; } # qr_code_scanner etc if used

# Dio
-keep class dio.http.** { *; }
-dontwarn dio.http.**

# Retrofit / JsonSerializable (if used dynamically)
-keepnames class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Ignore common harmless warnings
-dontwarn io.flutter.embedding.**
-dontwarn javax.annotation.**
-dontwarn retrofit2.**
