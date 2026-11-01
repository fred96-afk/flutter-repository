import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lee las credenciales de firma desde android/key.properties (ver android/.gitignore).
// En CI, el workflow genera este archivo a partir de los secretos de GitHub.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val keystoreStoreFile: File? = keystoreProperties.getProperty("storeFile")?.let { storeFilePath ->
    if (File(storeFilePath).isAbsolute) File(storeFilePath) else file(storeFilePath)
}

val hasReleaseSigning = keystorePropertiesFile.exists() &&
    keystoreStoreFile?.exists() == true &&
    keystoreProperties.getProperty("storePassword") != null &&
    keystoreProperties.getProperty("keyAlias") != null &&
    keystoreProperties.getProperty("keyPassword") != null

if (keystorePropertiesFile.exists() && !hasReleaseSigning) {
    logger.warn(
        "android/key.properties existe pero la firma de release está incompleta " +
            "o el keystore no existe. Se usará la firma de debug."
    )
}

android {
    namespace = "com.example.polleria_movil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.polleria_movil"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            maybeCreate("release").apply {
                storeFile = keystoreStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Si no hay keystore configurado se usa la firma de debug para
            // permitir compilaciones locales. En CI se configura la firma real.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
