plugins {
    id ("com.android.application")
    id ("kotlin-android")
    id ("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    jvmToolchain(17) // Java version defined here
}

android {
    namespace = "dev.rohanjoshi.example"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.rohanjoshi.example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
