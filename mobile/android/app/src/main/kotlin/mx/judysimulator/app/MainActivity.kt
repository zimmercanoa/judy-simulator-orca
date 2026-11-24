package mx.judysimulator.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal. Expone el canal "judy/seguridad" para activar
 * FLAG_SECURE (bloquea capturas de pantalla y la vista previa en
 * "recientes") solo mientras se muestran pantallas sensibles.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "judy/seguridad")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pantallaSegura" -> {
                        val activar = call.argument<Boolean>("activar") ?: false
                        runOnUiThread {
                            if (activar) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
