package br.com.fanhub.goias

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Precisam existir ANTES de qualquer push chegar, senão a notificação no
    // canal correspondente (ver AndroidManifest.xml e o Edge Function
    // notifications-dispatch) fica muda no Android 8+ — o SO não cria canal
    // sozinho a partir do meta-data, só lê o id declarado.
    //
    // 2 canais, propositalmente separados:
    //  - NOTIFICATION_CHANNEL_ID ("*_matches"): ingressos/check-in
    //    (`match_access_open`), IMPORTANCE_DEFAULT — som + aparece na tela,
    //    nunca heads-up (nunca precisou de urgência).
    //  - NOTIFICATION_LIVE_CHANNEL_ID ("*_live_match_alerts_v2"): os 6
    //    eventos de jogo ao vivo (kickoff, gol a favor/contra, intervalo, 2º
    //    tempo, fim), IMPORTANCE_HIGH — heads-up/pop-up (M-live: eventos
    //    temporais, o usuário quer ver na hora). Nunca junta os 2 no mesmo
    //    canal — o Android nunca promove a importância de um canal já
    //    criado no aparelho, só um channel_id novo resolve isso.
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // M4.3B — id/nome vêm de `BuildConfig` (gerado por flavor, ver
            // `productFlavors` em build.gradle.kts) em vez de literal fixo,
            // pra bater com `${notificationChannelId}` do AndroidManifest.xml
            // em CADA flavor, sem precisar de 2 cópias deste arquivo.
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    BuildConfig.NOTIFICATION_CHANNEL_ID,
                    BuildConfig.NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    BuildConfig.NOTIFICATION_LIVE_CHANNEL_ID,
                    BuildConfig.NOTIFICATION_LIVE_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }
    }
}
