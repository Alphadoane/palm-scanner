package com.example.palmistry

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.util.Log
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

data class Node(val id: Int, val x: Float, val y: Float, val type: String)

data class PalmFeatures(
    val lineScores: Map<String, Float>,
    val complexity: Float
)

class InferenceEngine(context: Context) {
    
    private var interpreter: Interpreter? = null
    private val lineNames = listOf(
        "life_line", "head_line", "heart_line", "fate_line", "sun_line",
        "health_line", "marriage_line", "money_line", "travel_lines",
        "girdle_of_venus", "ring_of_solomon", "ring_of_saturn", "ring_of_apollo",
        "ring_of_mercury", "bracelet_lines", "background"
    )

    init {
        try {
            Log.d("InferenceEngine", "Initializing InferenceEngine...")
            val modelFile = loadModelFile(context.assets, "palm_segmentation_full.tflite")
            interpreter = Interpreter(modelFile)
            Log.d("InferenceEngine", "TFLite Interpreter created successfully")
        } catch (e: Exception) {
            Log.e("InferenceEngine", "FAILED to load TFLite model: ${e.message}", e)
        }
    }

    private fun loadModelFile(assetManager: AssetManager, modelPath: String): ByteBuffer {
        val fileDescriptor = assetManager.openFd(modelPath)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    fun runSegmentation(bitmap: Bitmap): Array<Array<Array<FloatArray>>> {
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 224, 224, true)
        val input = ByteBuffer.allocateDirect(224 * 224 * 3 * 4)
        input.order(ByteOrder.nativeOrder())
        
        val pixels = IntArray(224 * 224)
        scaledBitmap.getPixels(pixels, 0, 224, 0, 0, 224, 224)
        for (pixel in pixels) {
            input.putFloat(((pixel shr 16 and 0xFF) / 255.0f))
            input.putFloat(((pixel shr 8 and 0xFF) / 255.0f))
            input.putFloat(((pixel and 0xFF) / 255.0f))
        }

        val output = Array(1) { Array(224) { Array(224) { FloatArray(16) } } }
        if (interpreter == null) {
            Log.e("InferenceEngine", "Interpreter is NULL, skipping inference")
            return output
        }
        
        Log.d("InferenceEngine", "Running inference...")
        interpreter?.run(input, output)
        Log.d("InferenceEngine", "Inference complete")
        return output
    }

    fun extractNodes(segmentation: Array<Array<Array<FloatArray>>>): List<Node> {
        val nodes = mutableListOf<Node>()
        val threshold = 0.5f
        
        // Find peaks for each line type
        for (c in 0 until 15) {
            var maxVal = 0f
            var maxX = 0
            var maxY = 0
            
            for (y in 0 until 224) {
                for (x in 0 until 224) {
                    val score = segmentation[0][y][x][c]
                    if (score > maxVal) {
                        maxVal = score
                        maxX = x
                        maxY = y
                    }
                }
            }
            
            if (maxVal > threshold) {
                nodes.add(Node(c, maxX.toFloat(), maxY.toFloat(), lineNames[c]))
            }
        }
        return nodes
    }

    fun buildEdges(nodes: List<Node>): List<Pair<Int, Int>> {
        val edges = mutableListOf<Pair<Int, Int>>()
        // For AR visualization, we connect the 3 major lines if they exist
        // This is a simplified connector for the demo
        if (nodes.any { it.type == "life_line" } && nodes.any { it.type == "head_line" }) {
            val n1 = nodes.find { it.type == "life_line" }!!.id
            val n2 = nodes.find { it.type == "head_line" }!!.id
            edges.add(Pair(n1, n2))
        }
        return edges
    }

    fun extractFeatures(nodes: List<Node>): PalmFeatures {
        val scores = nodes.associate { it.type to 1.0f }
        return PalmFeatures(scores, nodes.size / 15.0f)
    }

    fun interpret(features: PalmFeatures): List<String> {
        val result = mutableListOf<String>()
        
        // Apply Rules based on palm_rules.json
        val lifeLineScore = features.lineScores["life_line"] ?: 0f
        val headLineScore = features.lineScores["head_line"] ?: 0f
        val heartLineScore = features.lineScores["heart_line"] ?: 0f
        val fateLineScore = features.lineScores["fate_line"] ?: 0f

        // Physical Vitality (R001)
        if (lifeLineScore > 0.7f) {
            result.add("Physical Vitality: High")
        } else if (lifeLineScore > 0.3f) {
            result.add("Physical Vitality: Moderate")
        }

        // Analytical Thinking (R003)
        if (headLineScore > 0.8f) {
            result.add("Analytical Thinking: High")
        } else if (headLineScore > 0.4f) {
            result.add("Pragmatic Thinking")
        }

        // Emotional Idealism (R002)
        if (heartLineScore > 0.7f) {
            result.add("Emotional Idealism: High")
        }

        // Fate and Direction
        if (fateLineScore > 0.5f) {
            result.add("Driven Personality")
        }

        if (result.isEmpty()) result.add("Scanning for features...")
        return result
    }
}
