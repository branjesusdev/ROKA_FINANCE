package com.brandol.finance_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.speech.RecognitionService
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Respaldo del dictado: abre la ventana de reconocimiento de voz de Google
 * (la misma que usa el teclado). Sirve en teléfonos cuyo reconocedor por
 * defecto no es Google (Honor, Huawei…). Prefiere el modo sin conexión.
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "diagnose") {
                    result.success(diagnose())
                    return@setMethodCallHandler
                }
                if (call.method != "recognize") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "Ya hay un dictado abierto", null)
                    return@setMethodCallHandler
                }
                val language = call.argument<String>("language") ?: "es-CO"
                val prompt = call.argument<String>("prompt")
                startDictation(language, prompt, result)
            }
    }

    private fun startDictation(
        language: String,
        prompt: String?,
        result: MethodChannel.Result,
    ) {
        val base = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            prompt?.let { putExtra(RecognizerIntent.EXTRA_PROMPT, it) }
        }
        // Primero Google; si no está, cualquier app de dictado instalada.
        val google = Intent(base).setPackage(GOOGLE_APP)
        val intent = if (google.resolveActivity(packageManager) != null) google else base
        try {
            pendingResult = result
            startActivityForResult(intent, REQUEST_CODE)
        } catch (e: ActivityNotFoundException) {
            pendingResult = null
            result.error("no_dictation_app", "No hay app de dictado", null)
        }
    }

    /** Qué reconocedores de voz ve Android (solo nombres de paquete). */
    private fun diagnose(): String {
        val services = packageManager
            .queryIntentServices(Intent(RecognitionService.SERVICE_INTERFACE), 0)
            .mapNotNull { it.serviceInfo?.packageName }
        val dialogs = packageManager
            .queryIntentActivities(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH), 0)
            .mapNotNull { it.activityInfo?.packageName }
        val default = Settings.Secure.getString(contentResolver, "voice_recognition_service")
        val onDevice = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(this)
        return listOf(
            "Android ${Build.VERSION.SDK_INT} · ${Build.MANUFACTURER} ${Build.MODEL}",
            "Por defecto: ${default ?: "ninguno"}",
            "Servicios: ${services.ifEmpty { listOf("ninguno") }.joinToString()}",
            "Ventanas: ${dialogs.ifEmpty { listOf("ninguna") }.joinToString()}",
            "Disponible: ${SpeechRecognizer.isRecognitionAvailable(this)} · en el equipo: $onDevice",
        ).joinToString("
")
    }

    @Deprecated("Requerido por FlutterActivity (no usa Activity Result API)")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CODE) return
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val text = data
            ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            ?.firstOrNull()
        result.success(text)
    }

    companion object {
        private const val CHANNEL = "finance_app/dictation"
        private const val GOOGLE_APP = "com.google.android.googlequicksearchbox"
        private const val REQUEST_CODE = 4107
    }
}
