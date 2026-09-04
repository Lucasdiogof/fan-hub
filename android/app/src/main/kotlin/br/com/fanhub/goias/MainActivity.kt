package br.com.fanhub.goias

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Precisa existir ANTES de qualquer push chegar, senão a notificação no
    // canal "goias_matches" (ver AndroidManifest.xml e o Edge Function
    // notifications-dispatch) fica muda no Android 8+ — o SO não cria canal
    // sozinho a partir do meta-data, só lê o id declarado. Importância
    // padrão de propósito (som + aparece na tela, nunca heads-up máxima
    // pra toda notificação).
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // M4.3B — id/nome vêm de `BuildConfig` (gerado por flavor, ver
            // `productFlavors` em build.gradle.kts) em vez de literal fixo,
            // pra bater com `${notificationChannelId}` do AndroidManifest.xml
            // em CADA flavor, sem precisar de 2 cópias deste arquivo.
            val channel = NotificationChannel(
                BuildConfig.NOTIFICATION_CHANNEL_ID,
                BuildConfig.NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
