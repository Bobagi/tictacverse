package com.bobagi.tictacverse

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Entrega ao Flutter o link de convite do modo online (https://tictacverse.bobagi.space/m/CODIGO
/// ou tictacverse://m/CODIGO), sem plugin: o link que abriu o app e os que chegam com ele aberto.
class MainActivity : FlutterActivity() {
    private var links: MethodChannel? = null
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = intent?.takeIf { it.action == Intent.ACTION_VIEW }?.dataString
        links = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tictacverse/links").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(initialLink)
                    initialLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_VIEW) {
            intent.dataString?.let { links?.invokeMethod("onLink", it) }
        }
    }
}
