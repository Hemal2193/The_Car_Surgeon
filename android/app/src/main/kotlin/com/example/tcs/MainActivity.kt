package com.example.tcs

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.tcs/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val fileName = call.argument<String>("fileName") ?: ""
                    val fileBytes = call.argument<ByteArray>("fileBytes")
                    val subFolder = call.argument<String>("subFolder") ?: "TCS"

                    if (fileBytes == null || fileName.isEmpty()) {
                        result.error("INVALID_ARGS", "fileName and fileBytes are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = saveToDownloads(fileName, fileBytes, subFolder)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(fileName: String, fileBytes: ByteArray, subFolder: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ : Use MediaStore API
            val relativePath = Environment.DIRECTORY_DOWNLOADS + "/" + subFolder

            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            }

            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)

            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(fileBytes)
                    outputStream.flush()
                }
                return "$relativePath/$fileName"
            } else {
                throw Exception("Failed to create file in Downloads")
            }
        } else {
            // Android 9 and below : Direct file write
            @Suppress("DEPRECATION")
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val targetDir = File(downloadsDir, subFolder)
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            val file = File(targetDir, fileName)
            FileOutputStream(file).use { it.write(fileBytes) }
            return file.absolutePath
        }
    }
}