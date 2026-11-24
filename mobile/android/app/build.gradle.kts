import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ------------------------------------------------------------------
// Firma de release: se lee de android/key.properties (NO versionado,
// ver key.properties.example y mobile/store/PUBLICAR_EN_PLAY.md).
// ------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val tieneFirmaRelease = keystorePropertiesFile.exists()
if (tieneFirmaRelease) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Identificador definitivo en Google Play: NO se puede cambiar
    // después de publicar la primera versión.
    namespace = "mx.judysimulator.app"
    // Google Play exige apuntar a una API reciente (ver PUBLICAR_EN_PLAY.md).
    compileSdk = maxOf(36, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "mx.judysimulator.app"
        // Android 7.0+; flutter_secure_storage requiere API 23 o superior.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = maxOf(36, flutter.targetSdkVersion)
        // versionCode/versionName salen de "version:" en pubspec.yaml
        // (p. ej. 0.1.0+1 -> versionName 0.1.0, versionCode 1) y deben
        // coincidir con el tag git mobile-v0.1.0.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tieneFirmaRelease) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties se firma con la clave debug solo para
            // poder ejecutar `flutter run --release`; Play rechaza ese AAB.
            signingConfig = if (tieneFirmaRelease) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("JuDy: android/key.properties no existe; el release se firma con la clave DEBUG (no apto para Play).")
                signingConfigs.getByName("debug")
            }
            // R8: ofuscación + eliminación de código y recursos sin uso.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
