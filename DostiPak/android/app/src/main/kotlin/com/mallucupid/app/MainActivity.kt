package com.mallucupid.app

import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * MainActivity
 *
 * Hosts the Flutter app (com.mallucupid.app) and implements the
 * 'mallucupid/voice_recorder' MethodChannel used by the chat screen for
 * voice messages.
 *
 * Channel API:
 *  - start(path: String) -> String   : starts an AAC-LC recording into a .m4a
 *                                      file, returns the file path
 *  - stop()              -> String?  : stops the recording, returns the file
 *                                      path (or null when nothing recorded)
 *  - cancel()            -> null     : stops and deletes the partial file
 *
 * Backed by android.media.MediaRecorder (AAC-LC encoder, MPEG_4 container).
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "VoiceRecorder"
        private const val CHANNEL_NAME = "mallucupid/voice_recorder"
    }

    private var recorder: MediaRecorder? = null
    private var isRecording = false
    private var currentFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val path = call.arguments as? String
                        if (path.isNullOrEmpty()) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Output file path is required",
                                null
                            )
                        } else {
                            startRecording(path, result)
                        }
                    }
                    "stop" -> stopRecording(result)
                    "cancel" -> {
                        cancelRecording()
                        result.success(null)
                    }
                    "isRecording" -> result.success(isRecording)
                    else -> result.notImplemented()
                }
            }
    }

    /** MediaRecorder constructor differs on API 31+ */
    private fun createRecorder(): MediaRecorder {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
    }

    private fun startRecording(path: String, result: MethodChannel.Result) {
        if (isRecording) {
            result.error("ALREADY_RECORDING", "A recording is already in progress", null)
            return
        }
        try {
            // Make sure the target directory exists
            val outputFile = File(path)
            outputFile.parentFile?.let { parent ->
                if (!parent.exists()) parent.mkdirs()
            }

            recorder = createRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                // MPEG_4 container + AAC-LC encoder => .m4a output
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(128000)
                setAudioSamplingRate(44100)
                setOutputFile(path)
                prepare()
                start()
            }

            isRecording = true
            currentFilePath = path
            Log.d(TAG, "recording started: $path")
            result.success(path)
        } catch (e: Exception) {
            Log.e(TAG, "startRecording() failed", e)
            releaseRecorder()
            result.error("RECORD_ERROR", e.message, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result) {
        if (!isRecording || recorder == null) {
            result.success(null)
            return
        }
        try {
            recorder?.stop()
            Log.d(TAG, "recording stopped: $currentFilePath")
            result.success(currentFilePath)
        } catch (e: Exception) {
            Log.e(TAG, "stopRecording() failed", e)
            // A failed stop usually means the recording is unusable
            currentFilePath?.let { file ->
                File(file).delete()
            }
            result.error("RECORD_ERROR", e.message, null)
        } finally {
            releaseRecorder()
        }
    }

    private fun cancelRecording() {
        if (isRecording) {
            try {
                recorder?.stop()
            } catch (_: Exception) {
                // ignore - recorder was never started properly
            }
        }
        // Delete the partial file
        currentFilePath?.let { file ->
            try {
                File(file).delete()
                Log.d(TAG, "recording cancelled, file deleted: $file")
            } catch (_: Exception) {
                // ignore
            }
        }
        releaseRecorder()
    }

    private fun releaseRecorder() {
        try {
            recorder?.release()
        } catch (_: Exception) {
            // ignore
        }
        recorder = null
        isRecording = false
        currentFilePath = null
    }

    override fun onDestroy() {
        // Never leak a MediaRecorder
        cancelRecording()
        super.onDestroy()
    }
}
