# ProGuard rules for Cadife Smart Travel
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Isar
-keep class * extends isar.IsarObject { *; }
-keep class * extends isar.IsarEmbedded { *; }
-keep class * implements isar.IsarLink { *; }
-keep class * implements isar.IsarLinks { *; }
-keep class isar.** { *; }
-dontwarn isar.**

# Dio
-keep class com.squareup.dio.** { *; }
-dontwarn com.squareup.dio.**
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# General
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
