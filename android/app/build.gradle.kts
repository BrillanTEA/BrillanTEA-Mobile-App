import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clave de firma propia (android/key.properties + android/app/brillantea.jks). Si no existen, usa la de depuración.
val propiedadesClave = Properties()
val archivoPropiedadesClave = rootProject.file("key.properties")
if (archivoPropiedadesClave.exists()) {
    propiedadesClave.load(FileInputStream(archivoPropiedadesClave))
}

android {
    namespace = "pe.brillantea.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identificador final de la app en Android (también es el namespace del código nativo)
        applicationId = "pe.brillantea.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (archivoPropiedadesClave.exists()) {
                keyAlias = propiedadesClave["keyAlias"] as String
                keyPassword = propiedadesClave["keyPassword"] as String
                storeFile = file(propiedadesClave["storeFile"] as String)
                storePassword = propiedadesClave["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (archivoPropiedadesClave.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.concurrent:concurrent-futures:1.2.0")
}

flutter {
    source = "../.."
}
