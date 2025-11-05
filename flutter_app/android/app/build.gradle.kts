plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.4" apply false
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = 1
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = "1.0.0"
}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
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
        targetSdkVersion 34 // Update to latest
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName

        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
        }
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['key.alias']
            keyPassword keystoreProperties['key.password']
            storeFile file(keystoreProperties['store.file'] ? file(keystoreProperties['storeFile']): nul)
            storePassword keystoreProperties['store.password']
        }
    }

    buildTypes {
        release {
            
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
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
