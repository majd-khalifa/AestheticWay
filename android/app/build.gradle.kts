plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// CI supplies release signing through its secret store; no key or password is
// committed, and release tasks never fall back to the Android debug certificate.
val releaseStore = providers.environmentVariable("AW_ANDROID_STORE_FILE").orNull
val releaseStorePassword = providers.environmentVariable("AW_ANDROID_STORE_PASSWORD").orNull
val releaseAlias = providers.environmentVariable("AW_ANDROID_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("AW_ANDROID_KEY_PASSWORD").orNull
val hasReleaseSigning = listOf(releaseStore, releaseStorePassword, releaseAlias, releaseKeyPassword)
    .all { !it.isNullOrBlank() }

android {
    namespace = "com.aestheticway.aesthetic_way"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aestheticway.aesthetic_way"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStore!!)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    val buildingAppRelease = allTasks.any {
        it.project.path == ":app" &&
            (it.name == "assembleRelease" || it.name == "bundleRelease" || it.name == "packageRelease")
    }
    if (buildingAppRelease && !hasReleaseSigning) {
        throw GradleException("Release signing is not configured. Supply the four AW_ANDROID signing variables through CI secrets.")
    }
}
