plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cadife.cadife_smart_travel"
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
        applicationId = "com.cadife.cadife_smart_travel"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions.add("environment")
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
        }
        create("prod") {
            dimension = "environment"
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore/cadife-tour.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }

        create("staging") {
            storeFile = file("keystore/cadife-tour-staging.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD_STAGING")
            keyAlias = System.getenv("KEY_ALIAS_STAGING")
            keyPassword = System.getenv("KEY_PASSWORD_STAGING")
        }

        create("dev") {
            storeFile = file("keystore/cadife-tour-dev.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD_DEV")
            keyAlias = System.getenv("KEY_ALIAS_DEV")
            keyPassword = System.getenv("KEY_PASSWORD_DEV")
        }
    }

    buildTypes {
        getByName("release") {
            // TODO: Replace with a real secret key for signing the release APK
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }

        create("staging") {
            signingConfig = signingConfigs.getByName("staging")
            isMinifyEnabled = true
            isDebuggable = false
        }

        getByName("debug") {
            signingConfig = signingConfigs.getByName("dev")
            isMinifyEnabled = false
            isDebuggable = true
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}