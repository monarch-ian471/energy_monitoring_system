plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.4" apply false
}

android {
    namespace = "com.iankatengeza.energy_monitor_app"
    compileSdk = 35  // Set to Android 14 (API 34)
    ndkVersion = "27.0.12077973"  // Set to required NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId "com.iankatengeza.energy_monitor_app"
        minSdkVersion 21  // Change from flutter.minSdkVersion to 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    buildscript {
        ext.kotlin_version = '1.9.22'  // Update if older
        repositories {
            google()
            mavenCentral()
        }

        dependencies {
            classpath 'com.android.tools.build:gradle:8.1.4'
            classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
            classpath 'com.google.gms:google-services:4.4.2'  // ADD THIS LINE
        }
    }

    apply plugin: 'com.google.gms.google-services' 
}

flutter {
    source = "../.."
}
