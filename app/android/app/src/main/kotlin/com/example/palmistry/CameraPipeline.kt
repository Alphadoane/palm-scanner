package com.example.palmistry

import android.content.Context
import android.graphics.*
import android.media.Image
import android.util.Log
import android.util.Size
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class CameraPipeline(
    private val context: Context,
    private val surfaceProvider: Preview.SurfaceProvider,
    private val onUpdate: (List<String>, Float, List<Map<String, Any>>, List<List<Int>>, List<Map<String, Any>>) -> Unit
) {
    private val TAG = "PalmCameraPipeline"
    private val inferenceEngine = InferenceEngine(context)
    private val temporalSmoother = TemporalSmoother()
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    
    private var cameraProvider: ProcessCameraProvider? = null
    private val isCaptureRequested = AtomicBoolean(false)
    private var onCaptureResult: ((List<String>, Float, List<Map<String, Any>>, List<List<Int>>, List<Map<String, Any>>) -> Unit)? = null

    init {
        Log.d(TAG, "CameraPipeline initialized")
    }

    fun startCameraPipeline() {
        Log.d(TAG, "Starting camera pipeline...")
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                Log.d(TAG, "CameraProvider obtained successfully")
                bindCameraUseCases()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get CameraProvider: ${e.message}", e)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindCameraUseCases() {
        val provider = cameraProvider ?: run {
            Log.e(TAG, "bindCameraUseCases: cameraProvider is null")
            return
        }
        
        Log.d(TAG, "Binding use cases...")
        
        val preview = Preview.Builder()
            .setTargetResolution(Size(1280, 720))
            .build()
        preview.setSurfaceProvider(surfaceProvider)

        val imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(Size(224, 224))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()

        imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(imageProxy)
        }

        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

        try {
            provider.unbindAll()
            if (context is LifecycleOwner) {
                Log.d(TAG, "Context is LifecycleOwner, binding use cases")
                provider.bindToLifecycle(context as LifecycleOwner, cameraSelector, preview, imageAnalysis)
                Log.d(TAG, "Camera bound to lifecycle")
            } else {
                Log.e(TAG, "CRITICAL ERROR: Context is NOT a LifecycleOwner (${context.javaClass.simpleName})")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Binding use cases failed with error: ${e.message}", e)
        }
    }

    fun captureNow(callback: (List<String>, Float, List<Map<String, Any>>, List<List<Int>>, List<Map<String, Any>>) -> Unit) {
        Log.d(TAG, "Capture requested!")
        onCaptureResult = callback
        isCaptureRequested.set(true)
    }

    fun stopCameraPipeline() {
        Log.d(TAG, "Stopping camera pipeline")
        cameraProvider?.unbindAll()
        cameraExecutor.shutdown()
    }

    @androidx.annotation.OptIn(androidx.camera.core.ExperimentalGetImage::class)
    private fun processImageProxy(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage == null) {
            Log.w(TAG, "processImageProxy: mediaImage is null")
            imageProxy.close()
            return
        }
        
        val bitmap = imageToBitmap(mediaImage)
        if (bitmap != null) {
            if (isCaptureRequested.getAndSet(false)) {
                Log.d(TAG, "Processing capture frame...")
                runFullAnalysis(bitmap, onCaptureResult)
                onCaptureResult = null
            } else {
                runPreviewAnalysis(bitmap)
            }
        } else {
            Log.e(TAG, "Failed to convert Image to Bitmap")
        }
        imageProxy.close()
    }

    private fun runPreviewAnalysis(bitmap: Bitmap) {
        try {
            val segmentation = inferenceEngine.runSegmentation(bitmap)
            val rawNodes = inferenceEngine.extractNodes(segmentation)
            val features = inferenceEngine.extractFeatures(rawNodes)
            val interpretation = inferenceEngine.interpret(features)
            
            val pointMap = rawNodes.associate { it.id.toString() to PointF(it.x, it.y) }
            val smoothedPoints = temporalSmoother.smooth(pointMap)
            
            val nodes = rawNodes.map { node ->
                val p = smoothedPoints[node.id.toString()] ?: PointF(node.x, node.y)
                mapOf("id" to node.id, "x" to p.x, "y" to p.y)
            }
            
            onUpdate(interpretation, 0.8f, nodes, emptyList(), emptyList())
        } catch (e: Exception) {
            Log.e(TAG, "runPreviewAnalysis failed: ${e.message}")
        }
    }

    private fun runFullAnalysis(bitmap: Bitmap, callback: ((List<String>, Float, List<Map<String, Any>>, List<List<Int>>, List<Map<String, Any>>) -> Unit)?) {
        try {
            Log.d(TAG, "Starting full neural analysis...")
            val segmentation = inferenceEngine.runSegmentation(bitmap)
            val rawNodes = inferenceEngine.extractNodes(segmentation)
            val edges = inferenceEngine.buildEdges(rawNodes)
            val features = inferenceEngine.extractFeatures(rawNodes)
            val interpretation = inferenceEngine.interpret(features)
            
            val nodes = rawNodes.map { mapOf("id" to it.id, "x" to it.x, "y" to it.y, "type" to it.type) }
            val edgePairs = edges.map { listOf(it.first, it.second) }
            val labelPositions = interpretation.mapIndexed { index, _ ->
                val node = nodes.getOrElse(index) { nodes.firstOrNull() ?: mapOf("x" to 0f, "y" to 0f) }
                mapOf("x" to (node["x"] as Float) + 20f, "y" to (node["y"] as Float) - 20f)
            }

            Log.d(TAG, "Full analysis complete. Labels: $interpretation")
            callback?.invoke(interpretation, 0.98f, nodes, edgePairs, labelPositions)
        } catch (e: Exception) {
            Log.e(TAG, "runFullAnalysis failed: ${e.message}", e)
        }
    }

    private fun imageToBitmap(image: Image): Bitmap? {
        return try {
            val yBuffer = image.planes[0].buffer
            val uBuffer = image.planes[1].buffer
            val vBuffer = image.planes[2].buffer

            val ySize = yBuffer.remaining()
            val uSize = uBuffer.remaining()
            val vSize = vBuffer.remaining()

            val nv21 = ByteArray(ySize + uSize + vSize)

            yBuffer.get(nv21, 0, ySize)
            vBuffer.get(nv21, ySize, vSize)
            uBuffer.get(nv21, ySize + vSize, uSize)

            val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, yuvImage.width, yuvImage.height), 100, out)
            val imageBytes = out.toByteArray()
            
            BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        } catch (e: Exception) {
            Log.e(TAG, "imageToBitmap failed: ${e.message}")
            null
        }
    }
}
