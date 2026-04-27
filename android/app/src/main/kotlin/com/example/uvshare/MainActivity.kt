package com.example.uvshare

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.uvshare/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getStorageInfo") {
                val storageInfo = getStorageInfo()
                if (storageInfo != null) {
                    result.success(storageInfo)
                } else {
                    result.error("UNAVAILABLE", "Storage info not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getStorageInfo(): Map<String, String>? {
        return try {
            // Using internal data directory path
            val internalPath = Environment.getDataDirectory().path
            val stat = StatFs(internalPath)
            
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong

            val totalBytes = totalBlocks * blockSize
            val freeBytes = availableBlocks * blockSize

            // Sending keys that match Dart: 'totalBytes' and 'freeBytes'
            mapOf(
                "totalBytes" to totalBytes.toString(),
                "freeBytes" to freeBytes.toString()
            )
        } catch (e: Exception) {
            null
        }
    }
}
