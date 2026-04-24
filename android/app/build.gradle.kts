// ============================================================
// build.gradle.kts — Android build configuration
//
// This file tells Gradle how to compile and package your app.
// Docs: https://developer.android.com/build
// ============================================================

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ============================================================
// Load signing credentials from key.properties
// We read them from a separate file so they never end up
// hardcoded in this file which IS committed to git
// ============================================================
val keyPropertiesFile = rootProject.file("../android/key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
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

    // ============================================================
    // signingConfigs — defines HOW to sign the app
    // We define a 'release' config that reads from key.properties
    // Docs: https://developer.android.com/build/build-variants#signing
    // ============================================================
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.ni6hant.systeminfo"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        // debug builds use debug signing — fine for development
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        // release builds use our keystore — required for Play Store
        // Docs: https://developer.android.com/build/build-variants#build-types
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // Enables code shrinking and obfuscation
            // Removes unused code to reduce APK size
            // Docs: https://developer.android.com/build/shrink-code
            isMinifyEnabled = true

            // Enables resource shrinking — removes unused resources
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
