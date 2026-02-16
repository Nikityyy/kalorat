plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.berger.kalorat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.berger.kalorat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            val keyAliasVar = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            val keyPasswordVar = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            val storePasswordVar = System.getenv("STORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            val keystorePathVar = System.getenv("KEYSTORE_PATH") ?: keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks"

            if (keyAliasVar != null && keyPasswordVar != null && storePasswordVar != null) {
                keyAlias = keyAliasVar
                keyPassword = keyPasswordVar
                storeFile = file(keystorePathVar)
                storePassword = storePasswordVar
            } else {
                // Fallback to debug if not in CI or secrets not set
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
