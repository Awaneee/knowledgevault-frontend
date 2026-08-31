# Flutter secure storage — keep encrypted prefs classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }

# Drift / SQLite — keep generated database classes
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kotlin coroutines (used by Drift)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Dio / OkHttp internals
-dontwarn okhttp3.**
-dontwarn okio.**

# Play Core — only needed for deferred components (not used)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep data model classes used by Gson / JSON reflection (if any)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
