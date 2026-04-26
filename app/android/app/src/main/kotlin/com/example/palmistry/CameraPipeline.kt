package com.example.palmistry

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.PointF
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

class CameraPipeline(private val context: Context, private val onFrameProcessed: (List<String>, Float, List<Map<String, Any>>, List<List<Int>>, List<Map<String, Any>>) -> Unit) {
    
    private val inferenceEngine = InferenceEngine()
    private val temporalSmoother = TemporalSmoother()
    private val cameraExecutor = Executors.newSingleThreadExecutor()

    fun startCameraPipeline() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val imageAnalysis = ImageAnalysis.Builder()
                .setTargetResolution(Size(224, 224))
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()

            imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
                processImageProxy(imageProxy)
            }

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider.unbindAll()
                if (context is LifecycleOwner) {
                    cameraProvider.bindToLifecycle(context as LifecycleOwner, cameraSelector, imageAnalysis)
                } else {
                    // Fallback to simulated processing if context is not LifecycleOwner
                    simulateFrameProcessing()
                }
            } catch (exc: Exception) {
                // If binding fails, use simulator
                simulateFrameProcessing()
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @androidx.annotation.OptIn(androidx.camera.core.ExperimentalGetImage::class)
    private fun processImageProxy(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val bitmap = imageToBitmap(mediaImage)
            if (bitmap != null) {
                processFrame(bitmap)
            }
        }
        imageProxy.close()
    }

    private fun imageToBitmap(image: Image): Bitmap? {
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
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    private fun processFrame(bitmap: Bitmap) {
        val segmentation = inferenceEngine.runSegmentation(bitmap)
        val skeleton = inferenceEngine.skeletonize(segmentation)
        val rawNodes = inferenceEngine.extractNodes(skeleton)
        val edges = inferenceEngine.buildEdges(skeleton, rawNodes)
        val features = inferenceEngine.extractFeatures(rawNodes)
        val interpretation = inferenceEngine.interpret(features)
        
        val pointMap = rawNodes.associate { it.id.toString() to PointF(it.x.toFloat(), it.y.toFloat()) }
        val smoothedPoints = temporalSmoother.smooth(pointMap)
        
        val nodes = rawNodes.map { node ->
            val p = smoothedPoints[node.id.toString()] ?: PointF(node.x.toFloat(), node.y.toFloat())
            mapOf("id" to node.id, "x" to p.x, "y" to p.y, "type" to node.type)
        }
        
        val edgePairs = edges.map { listOf(it.first, it.second) }
        
        val labelPositions = interpretation.mapIndexed { index, _ ->
            val node = nodes.getOrElse(index) { nodes.firstOrNull() ?: mapOf("x" to 0f, "y" to 0f) }
            mapOf("x" to (node["x"] as Float) + 20f, "y" to (node["y"] as Float) - 20f)
        }

        onFrameProcessed(interpretation, 0.85f, nodes, edgePairs, labelPositions)
    }
    
    private fun simulateFrameProcessing() {
        Thread {
            while (true) {
                Thread.sleep(100) // ~10fps
                val dummyNodes = listOf(
                    mapOf("id" to 0, "x" to 150f, "y" to 200f, "type" to "endpoint"),
                    mapOf("id" to 1, "x" to 180f, "y" to 300f, "type" to "junction"),
                    mapOf("id" to 2, "x" to 120f, "y" to 400f, "type" to "endpoint")
                )
                val dummyEdges = listOf(listOf(0, 1), listOf(1, 2))
                val labels = listOf("High Vitality", "Analytical Thinker")
                val labelPos = listOf(
                    mapOf("x" to 160f, "y" to 180f),
                    mapOf("x" to 190f, "y" to 280f)
                )
                onFrameProcessed(labels, 0.92f, dummyNodes, dummyEdges, labelPos)
            }
        }.start()
    }
}
