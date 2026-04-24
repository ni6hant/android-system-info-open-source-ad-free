plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ni6hant.systeminfo"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

defaultConfig {
        // Your app's unique identifier on the Play Store.
        // Before publishing you MUST change this from com.example
        // to something unique like com.yournname.systeminfo
        // Docs: https://developer.android.com/studio/build/application-id
        applicationId = "com.ni6hant.systeminfo"

        // Minimum Android version that can install this app.
        // 21 = Android 5.0 Lollipop — covers 99%+ of active devices.
        // We set this explicitly rather than relying on Flutter's default
        // so we always know exactly what we're targeting.
        // Docs: https://developer.android.com/reference/android/os/Build.VERSION_CODES
        minSdk = flutter.minSdkVersion

        // The Android version we've tested and optimized for.
        // Google requires this to be 33+ for new Play Store submissions.
        // Docs: https://developer.android.com/google/play/requirements/target-sdk
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
