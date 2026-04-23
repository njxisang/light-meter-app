package com.example.light_meter_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private val LIGHT_SENSOR_CHANNEL = "light_meter/light_sensor"
    private val LIGHT_SENSOR_EVENT_CHANNEL = "light_meter/light_sensor/events"

    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

        // Method Channel for availability check
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_SENSOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        result.success(lightSensor != null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // Event Channel for sensor events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_SENSOR_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startListening()
                }

                override fun onCancel(arguments: Any?) {
                    stopListening()
                    eventSink = null
                }
            })
    }

    private fun startListening() {
        lightSensor?.let { sensor ->
            sensorManager?.registerListener(
                this,
                sensor,
                SensorManager.SENSOR_DELAY_UI
            )
        }
    }

    private fun stopListening() {
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            if (it.sensor.type == Sensor.TYPE_LIGHT) {
                val lux = it.values[0]
                eventSink?.success(mapOf("lux" to lux))
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }
}
