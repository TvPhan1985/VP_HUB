package vn.phan.vphub

import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Kenh nho cho man Quet: Android 6-11 phai bat cong tac Location moi quet duoc BLE
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.phan.vphub/sys").setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "locationEnabled" -> {
                    val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                    val on = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        lm.isLocationEnabled
                    } else {
                        lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                            lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                    }
                    result.success(on)
                }
                "openLocationSettings" -> {
                    startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
