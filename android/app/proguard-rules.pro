# Flutter core
-keep class io.flutter.** { *; }

# CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Permissions
-keep class com.permission.** { *; }
-dontwarn com.permission.**

# Saver Gallery
-keep class com.safeds.gallery.** { *; }

# Play Core (for deferred modules and safety)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Prevent removal of code used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes *Annotation*
