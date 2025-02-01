package com.example.ocr_tf

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.flex.FlexDelegate
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.io.FileInputStream

class MainActivity : FlutterActivity() {

    private val channel = "com.example.ocr_tf/tflite"
    private lateinit var interpreter: Interpreter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadInterpreter" -> loadInterpreter(result)
                "runModel" -> {
                    val inputTensor = call.argument<ByteArray>("inputTensor")!! 
                    runModel(inputTensor, result)
                }
                else -> result.notImplemented()
            }
        }
    }    

    private fun loadInterpreter(result: MethodChannel.Result) {
        try {
            val modelFileDescriptor = assets.openFd("model.tflite")
            val modelFile = FileInputStream(modelFileDescriptor.fileDescriptor)
            val fileChannel = modelFile.channel
            val modelByteBuffer: MappedByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, modelFileDescriptor.startOffset, modelFileDescriptor.length)

            val options = Interpreter.Options()
            options.addDelegate(FlexDelegate())

            interpreter = Interpreter(modelByteBuffer, options)

            result.success("Interpreter loaded successfully")
        } catch (e: Exception) {
            result.error("ERROR", "Failed to load interpreter: ${e.message}", null)
        }
    }
    
    private fun runModel(inputTensor: ByteArray, result: MethodChannel.Result) {
        try {
            val inputBuffer = ByteBuffer.allocateDirect(inputTensor.size).apply {
                order(ByteOrder.nativeOrder())
                put(inputTensor)
            }
    
            val detectionClasses = Array(1) { FloatArray(100) } 
            val detectionBoxes = Array(1) { Array(100) { FloatArray(4) } }
            val detectionScores = Array(1) { FloatArray(100) } 
            val detectionMulticlassScores = Array(1) { Array(100) { FloatArray(9) } } 
            val rawDetectionScores = Array(1) { FloatArray(100) } 
            val numDetections = FloatArray(1)
            val rawDetectionBoxes = Array(1) { Array(81840) { FloatArray(4) } } 
            val detectionAnchorIndices = Array(1) { Array(81840) { FloatArray(9) } } 
    
            val outputs = mapOf(
                0 to detectionScores,
                1 to detectionBoxes,
                2 to detectionClasses,
                3 to detectionMulticlassScores,
                4 to rawDetectionScores,
                5 to numDetections,
                6 to rawDetectionBoxes,
                7 to detectionAnchorIndices
            )
    
            interpreter.runForMultipleInputsOutputs(arrayOf(inputBuffer), outputs)
    
            val results = mapOf(
                "detectionClasses" to detectionClasses[0].toList(),
                "detectionBoxes" to detectionBoxes[0].map { it.toList() },
                "detectionScores" to detectionScores[0].toList(),
                "detectionMulticlassScores" to detectionMulticlassScores[0].map { it.toList() },
                "rawDetectionScores" to rawDetectionScores[0].toList(),
                "numDetections" to listOf(numDetections[0]), 
                "rawDetectionBoxes" to rawDetectionBoxes[0].map { it.toList() },
                "detectionAnchorIndices" to detectionAnchorIndices[0].map { it.toList() }
            )
    
            result.success(results)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to run model inference: ${e.message}", null)
        }
    }    
}
