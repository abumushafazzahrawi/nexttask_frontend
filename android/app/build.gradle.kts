plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    
}

android {
    // tambahkan baris ini (wajib di AGP versi terbaru)
    namespace = "com.example.nextask"

    ndkVersion = "28.2.13676358"

    // 1. compileSdkVersion diubah menjadi fungsi dengan tanda kurung ()
    compileSdkVersion(flutter.compileSdkVersion)
    
    defaultConfig {
        // 2. applicationId diubah menggunakan tanda sama dengan =
        applicationId = "com.example.nextask" 
        
        // 3. minSdkVersion & targetSdkVersion diubah menjadi =
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        
        // 4. versionCode & versionName diubah menggunakan tanda sama dengan =
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 5. MultiDex di Kotlin DSL ditulis menggunakan properti multidexEnabled = true
        multiDexEnabled = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // ➕ TAMBAHKAN BLOK KOTLIN OPTIONS INI DI SINI
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

// Bagian dependencies yang paling bawah tetap seperti ini:
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-messaging")
    
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
