package com.brandol.finance_app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.speech.RecognitionService
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Copia de seguridad: selector de archivos de Android para guardar o abrir
 * el JSON (canal [BACKUP_CHANNEL]).
 *
 * Respaldo del dictado: abre la ventana de reconocimiento de voz de Google
 * (la misma que usa el teclado). Sirve en teléfonos cuyo reconocedor por
 * defecto no es Google (Honor, Huawei…). Prefiere el modo sin conexión.
 */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBackup: MethodChannel.Result? = null
    private var pendingBackupContent: String? = null

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
                val preferOffline = call.argument<Boolean>("preferOffline") ?: true
                startDictation(language, prompt, preferOffline, result)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (pendingBackup != null) {
                    result.error("busy", "Ya hay un archivo abierto", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "save" -> {
                        val name = call.argument<String>("fileName") ?: "copia.json"
                        val content = call.argument<String>("content") ?: ""
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = JSON_MIME
                            putExtra(Intent.EXTRA_TITLE, name)
                        }
                        pendingBackupContent = content
                        launchBackup(intent, SAVE_REQUEST_CODE, result)
                    }
                    "open" -> {
                        // Algunos gestores no reconocen .json: se acepta
                        // cualquier archivo y se valida al importar.
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        launchBackup(intent, OPEN_REQUEST_CODE, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchBackup(intent: Intent, requestCode: Int, result: MethodChannel.Result) {
        try {
            pendingBackup = result
            startActivityForResult(intent, requestCode)
        } catch (e: ActivityNotFoundException) {
            pendingBackup = null
            pendingBackupContent = null
            result.error("no_file_app", "No hay selector de archivos", null)
        }
    }

    /** Lee o escribe fuera del hilo principal y responde en él. */
    private fun finishBackup(requestCode: Int, uri: Uri) {
        val result = pendingBackup ?: return
        val content = pendingBackupContent
        pendingBackup = null
        pendingBackupContent = null
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                if (requestCode == SAVE_REQUEST_CODE) {
                    contentResolver.openOutputStream(uri, "wt")?.use {
                        it.write((content ?: "").toByteArray(Charsets.UTF_8))
                    } ?: throw IllegalStateException("sin salida")
                    main.post { result.success(true) }
                } else {
                    val text = contentResolver.openInputStream(uri)?.use {
                        it.readBytes().toString(Charsets.UTF_8)
                    } ?: throw IllegalStateException("sin entrada")
                    main.post { result.success(text) }
                }
            } catch (e: Exception) {
                main.post { result.error("io", "No se pudo leer o escribir", null) }
            }
        }.start()
    }

    private fun startDictation(
        language: String,
        prompt: String?,
        preferOffline: Boolean,
        result: MethodChannel.Result,
    ) {
        val base = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, language)
            // Sin paquete sin conexión, exigirlo hace fallar a Google con
            // "la búsqueda por voz no está disponible".
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, preferOffline)
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
        ).joinToString("\n")
    }

    @Deprecated("Requerido por FlutterActivity (no usa Activity Result API)")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SAVE_REQUEST_CODE || requestCode == OPEN_REQUEST_CODE) {
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                val result = pendingBackup
                pendingBackup = null
                pendingBackupContent = null
                // Cancelado: guardar devuelve false, abrir devuelve null.
                result?.success(if (requestCode == SAVE_REQUEST_CODE) false else null)
                return
            }
            finishBackup(requestCode, uri)
            return
        }
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
        private const val BACKUP_CHANNEL = "finance_app/backup"
        private const val SAVE_REQUEST_CODE = 4108
        private const val OPEN_REQUEST_CODE = 4109
        private const val JSON_MIME = "application/json"
    }
}
