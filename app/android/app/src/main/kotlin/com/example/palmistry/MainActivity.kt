package com.example.palmistry

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "palm_ai"
    private val STREAM = "palm_stream"
    private var eventSink: EventChannel.EventSink? = null
    
    // Placeholder for actual camera pipeline
    private var cameraPipeline: CameraPipeline? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        cameraPipeline = CameraPipeline(this) { labels, confidence, nodes, edges, labelPositions ->
            sendResults(labels, confidence, nodes, edges, labelPositions)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "startCamera") {
                    cameraPipeline?.startCameraPipeline()
                    result.success(null)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun sendResults(labels: List<String>, confidence: Float, nodes: List<Map<String, Any>>, edges: List<List<Int>>, labelPositions: List<Map<String, Any>>) {
        val data = mapOf(
            "labels" to labels,
            "confidence" to confidence,
            "nodes" to nodes,
            "edges" to edges,
            "labelPositions" to labelPositions
        )
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(data)
        }
    }
}
