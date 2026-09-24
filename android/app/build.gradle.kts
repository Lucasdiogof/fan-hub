import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keystore de release — lido de android/key.properties (nunca commitado,
// ver android/key.properties.example pro formato). Debug/profile builds
// nunca dependem disso (o `assemble`/`bundle` de release é que falha,
// nunca a configuração do projeto — ver `gradle.taskGraph.whenReady`
// abaixo). Sem `key.properties`, NENHUMA task de release consegue rodar:
// nunca mais cai silenciosamente pra assinatura de debug (um AAB assinado
// com debug parece "pronto" mas a Play Store rejeita/nunca deveria
// aceitar — falha alto e cedo é melhor que descobrir isso na hora do
// upload).
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
            // 2026-09-24: revertido pro nome oficial — build deixou de
            // mirar App Store (demo comercial pro clube agora), então a
            // identidade independente "Esmeraldino App" (Guideline 4.1(a))
            // saiu de uso.
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
            // Placeholder de CONFIGURAÇÃO só pro Gradle não quebrar ao avaliar
            // o projeto (ex.: abrir no Android Studio, `flutter analyze`) sem
            // key.properties. Nunca chega a ASSINAR nada de verdade com debug
            // — o `gradle.taskGraph.whenReady` abaixo barra a execução de
            // qualquer task de release antes disso importar.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

// Fail-fast real: se alguma task de RELEASE for de fato executada
// (assembleGoiasRelease, bundleBragantinoRelease, etc. — cobre os 2
// flavors sem listar nome por nome) sem keystore configurado, a build
// para aqui, ANTES de gerar qualquer artefato — nunca produz um
// APK/AAB assinado com debug se passando por release.
gradle.taskGraph.whenReady {
    val runningReleaseTask = allTasks.any { it.name.contains("Release") }
    if (runningReleaseTask && !hasReleaseSigning) {
        throw GradleException(
            "Build de RELEASE sem keystore configurado. Crie android/key.properties " +
                "(copie de android/key.properties.example e gere o keystore com " +
                "`keytool -genkeypair ...`, ver o próprio arquivo de exemplo) antes de " +
                "gerar um APK/AAB de release real. Debug/profile builds continuam " +
                "funcionando normalmente sem isso.",
        )
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
