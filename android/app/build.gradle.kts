import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de assinatura do upload (upload key).
// Prioridade: variaveis de ambiente (CI/Codemagic) > android/key.properties (local).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

fun secret(envName: String, propertyName: String): String? =
    System.getenv(envName)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }

val storePasswordValue = secret("KEYSTORE_PASSWORD", "storePassword")
val keyPasswordValue = secret("KEY_PASSWORD", "keyPassword")
val keyAliasValue = secret("KEY_ALIAS", "keyAlias")
val storeFileValue = secret("KEYSTORE_FILE", "storeFile")
val hasReleaseSigning =
    storePasswordValue != null && keyPasswordValue != null && keyAliasValue != null && storeFileValue != null

if (!hasReleaseSigning) {
    throw GradleException(
        "Keystore de release nao encontrada. Defina android/key.properties (storePassword, keyPassword, " +
            "keyAlias, storeFile) ou as variaveis de ambiente KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS e " +
            "KEYSTORE_FILE. Sem isso o bundle seria assinado com a chave de debug e o Google Play recusaria " +
            "a publicacao."
    )
}

android {
    namespace = "com.tictactoeonline2.tictactoeonline2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tictactoeonline2.tictactoeonline2"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = file(storeFileValue!!)
            storePassword = storePasswordValue
        }
    }

    buildTypes {
        release {
            // Uses the release keystore for a signed release build.
            signingConfig = signingConfigs.getByName("release")
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

dependencies {
    // Resolve WorkManager crash on release builds (google_mobile_ads pulls an
    // outdated androidx.work version that fails to create the WorkDatabase).
    implementation("androidx.work:work-runtime:2.11.2")
}
