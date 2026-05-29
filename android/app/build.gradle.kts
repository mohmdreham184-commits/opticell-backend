plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase plugin
    id("com.google.gms.google-services")
}

android {
    ndkVersion = "28.2.13676358"
    ndkPath = "C:/Users/reham/AppData/Local/Android/sdk/ndk/28.2.13676358"

    namespace = "com.example.opticell"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.opticell"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
