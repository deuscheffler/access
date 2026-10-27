package com.omegatelecom.omega_access

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Proveedor propio para compartir las imágenes de los pases con WhatsApp. */
class OmegaFileProvider : FileProvider()

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omega/whatsapp")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "instalado" -> {
                        val paquete = call.argument<String>("paquete") ?: "com.whatsapp"
                        val ok = try {
                            packageManager.getPackageInfo(paquete, 0)
                            true
                        } catch (e: Exception) {
                            false
                        }
                        result.success(ok)
                    }
                    "enviar" -> {
                        try {
                            val numero = call.argument<String>("numero") ?: ""
                            val rutas = call.argument<List<String>>("archivos") ?: emptyList()
                            val texto = call.argument<String>("texto") ?: ""
                            val paquete = call.argument<String>("paquete") ?: "com.whatsapp"
                            val uris = ArrayList<Uri>()
                            for (ruta in rutas) {
                                uris.add(
                                    FileProvider.getUriForFile(
                                        this, "$packageName.omegafiles", File(ruta)
                                    )
                                )
                            }
                            val intent = if (uris.size == 1) {
                                Intent(Intent.ACTION_SEND).apply {
                                    putExtra(Intent.EXTRA_STREAM, uris[0])
                                }
                            } else {
                                Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                                }
                            }
                            intent.type = "image/png"
                            intent.setPackage(paquete)
                            intent.putExtra("jid", "$numero@s.whatsapp.net")
                            intent.putExtra(Intent.EXTRA_TEXT, texto)
                            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ENVIO", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
