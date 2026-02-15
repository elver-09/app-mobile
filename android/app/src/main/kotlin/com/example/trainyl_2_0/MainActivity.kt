package com.example.trainyl_2_0

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.camera2.CameraManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.trainyl/flashlight"
    private var cameraId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("Flashlight", "Configurando canal de flashlight...")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d("Flashlight", "Método recibido: ${call.method}")
                when (call.method) {
                    "enableFlashlight" -> {
                        try {
                            Log.d("Flashlight", "Encendiendo linterna...")
                            enableFlashlight()
                            Log.d("Flashlight", "Linterna encendida exitosamente")
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e("Flashlight", "Error encendiendo linterna", e)
                            result.error("FLASHLIGHT_ERROR", e.message, null)
                        }
                    }
                    "disableFlashlight" -> {
                        try {
                            Log.d("Flashlight", "Apagando linterna...")
                            disableFlashlight()
                            Log.d("Flashlight", "Linterna apagada exitosamente")
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e("Flashlight", "Error apagando linterna", e)
                            result.error("FLASHLIGHT_ERROR", e.message, null)
                        }
                    }
                    else -> {
                        Log.w("Flashlight", "Método no implementado: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
        
        Log.d("Flashlight", "Canal de flashlight configurado correctamente")
    }

    private fun enableFlashlight() {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraList = cameraManager.cameraIdList
        Log.d("Flashlight", "Cámaras disponibles: ${cameraList.size}")
        
        if (cameraId == null && cameraList.isNotEmpty()) {
            cameraId = cameraList[0]
            Log.d("Flashlight", "ID de cámara asignado: $cameraId")
        }
        
        if (cameraId != null) {
            cameraManager.setTorchMode(cameraId!!, true)
            Log.d("Flashlight", "Torch mode activado para cámara: $cameraId")
        } else {
            Log.e("Flashlight", "No se encontró ID de cámara")
        }
    }

    private fun disableFlashlight() {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        if (cameraId != null) {
            cameraManager.setTorchMode(cameraId!!, false)
            Log.d("Flashlight", "Torch mode desactivado para cámara: $cameraId")
        } else {
            Log.w("Flashlight", "No hay cámara activa para desactivar")
        }
    }
}
