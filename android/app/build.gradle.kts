import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keystore de release — lido de android/key.properties (nunca commitado,
// ver android/key.properties.example pro formato). Se o arquivo não
// existir (dev local, CI sem secret configurado), `releaseSigningProps`
// fica vazio e o release CONTINUA caindo no signingConfig de debug —
// zero mudança de comportamento até alguém criar o arquivo de verdade.
val keystorePropertiesFile = rootProject.file("key.properties")
val releaseSigningProps = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = releaseSigningProps.containsKey("storeFile")

android {
    // Rebrand Fan Hub — o namespace (package do código: R/BuildConfig) passa
    // a ser `br.com.fanhub.goias`, desacoplado do applicationId de cada flavor
    // (Gradle permite namespace != applicationId). MainActivity.kt movida pro
    // mesmo package.
    namespace = "br.com.fanhub.goias"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // M4.3B — `buildConfig` pra `buildConfigField` (canal de notificação por
    // flavor) gerar `BuildConfig.*`; `resValues` pra `resValue()` (nome do
    // app por flavor) — o AGP passou a exigir os dois habilitados
    // explicitamente, cada um por sua própria flag, mesmo já estando em uso
    // dentro de `productFlavors` abaixo.
    buildFeatures {
        buildConfig = true
        resValues = true
    }

    defaultConfig {
        // Rebrand Fan Hub. Cada flavor sobrescreve com o seu; este é só o base.
        applicationId = "br.com.fanhub.goias"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Rebrand Fan Hub — dimensão "club", 2 flavors REAIS: `goias`
    // (`br.com.fanhub.goias`) e `bragantino` (`br.com.fanhub.bragantino`).
    // Cada flavor lê SÓ o seu `src/<flavor>/google-services.json` oficial do
    // projeto Fan Hub; nenhum carrega o do outro. O flavor sintético `clubb`
    // foi removido (supersedido pelo Bragantino real).
    flavorDimensions += "club"
    productFlavors {
        create("goias") {
            dimension = "club"
            applicationId = "br.com.fanhub.goias"
            resValue("string", "app_name", "Goiás EC")
            manifestPlaceholders["notificationChannelId"] = "goias_matches"
            buildConfigField("String", "NOTIFICATION_CHANNEL_ID", "\"goias_matches\"")
            buildConfigField("String", "NOTIFICATION_CHANNEL_NAME", "\"Partidas do Goiás\"")
            // M-live — canal PRÓPRIO pros 6 eventos de jogo ao vivo (kickoff,
            // gol a favor/contra, intervalo, 2º tempo, fim), IMPORTANCE_HIGH
            // (heads-up). Nunca reaproveita "goias_matches" (IMPORTANCE_DEFAULT,
            // usado só por ingressos/check-in) — o Android NUNCA promove a
            // importância de um canal já criado no aparelho, só um channel_id
            // novo resolve isso (por isso o sufixo `_v2`, versionado).
            buildConfigField("String", "NOTIFICATION_LIVE_CHANNEL_ID", "\"goias_live_match_alerts_v2\"")
            buildConfigField("String", "NOTIFICATION_LIVE_CHANNEL_NAME", "\"Jogos ao vivo — Goiás\"")
        }
        create("bragantino") {
            dimension = "club"
            applicationId = "br.com.fanhub.bragantino"
            resValue("string", "app_name", "Red Bull Bragantino")
            manifestPlaceholders["notificationChannelId"] = "bragantino_matches"
            buildConfigField("String", "NOTIFICATION_CHANNEL_ID", "\"bragantino_matches\"")
            buildConfigField("String", "NOTIFICATION_CHANNEL_NAME", "\"Partidas do Bragantino\"")
            buildConfigField("String", "NOTIFICATION_LIVE_CHANNEL_ID", "\"bragantino_live_match_alerts_v2\"")
            buildConfigField("String", "NOTIFICATION_LIVE_CHANNEL_NAME", "\"Jogos ao vivo — Bragantino\"")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseSigningProps.getProperty("storeFile"))
                storePassword = releaseSigningProps.getProperty("storePassword")
                keyAlias = releaseSigningProps.getProperty("keyAlias")
                keyPassword = releaseSigningProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Usa o keystore de release real assim que `android/key.properties`
            // existir (ver android/key.properties.example) — até lá, cai no
            // signingConfig de debug (comportamento pré-existente, nunca
            // quebra quem ainda não configurou). Nenhuma senha/keystore
            // aparece aqui — tudo lido do arquivo local, nunca commitado.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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
