package com.example.palmistry

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.view.PreviewView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity: FlutterActivity() {
    private val CHANNEL = "palm_ai"
    private val STREAM = "palm_stream"
    private var eventSink: EventChannel.EventSink? = null
    
    private var cameraPipeline: CameraPipeline? = null
    private var previewView: PreviewView? = null
    private var startRequested = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the Native Camera View
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "native_camera_view",
            NativeCameraViewFactory()
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCamera" -> {
                        startRequested = true
                        tryStartCamera()
                        result.success(null)
                    }
                    "capture" -> {
                        cameraPipeline?.captureNow { labels, confidence, nodes, edges, labelPositions ->
                            val data = mapOf(
                                "labels" to labels,
                                "confidence" to confidence.toDouble(),
                                "nodes" to nodes,
                                "edges" to edges,
                                "labelPositions" to labelPositions
                            )
                            Handler(Looper.getMainLooper()).post {
                                result.success(data)
                            }
                        }
                    }
                    else -> result.notImplemented()
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

    private fun tryStartCamera() {
        if (startRequested && previewView != null) {
            cameraPipeline?.stopCameraPipeline()
            cameraPipeline = CameraPipeline(this, previewView!!.surfaceProvider) { labels, confidence, nodes, edges, labelPositions ->
                sendResults(labels, confidence, nodes, edges, labelPositions)
            }
            cameraPipeline?.startCameraPipeline()
        }
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

    inner class NativeCameraViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            return NativeCameraView(context)
        }
    }

    inner class NativeCameraView(context: Context) : PlatformView {
        private val container: FrameLayout = FrameLayout(context)
        private val view: PreviewView = PreviewView(context)

        init {
            view.layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            container.addView(view)
            previewView = view
            
            Handler(Looper.getMainLooper()).post {
                tryStartCamera()
            }
        }

        override fun getView(): View {
            return container
        }

        override fun dispose() {
            if (previewView == view) {
                cameraPipeline?.stopCameraPipeline()
                cameraPipeline = null
                previewView = null
            }
        }
    }
}
