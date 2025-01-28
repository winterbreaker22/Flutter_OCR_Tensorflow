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
            val inputBuffer = ByteBuffer.wrap(inputTensor).order(ByteOrder.nativeOrder())

            val rawDetectionBoxes = Array(1) { Array(81840) { FloatArray(4) } }
            val detectionScores = FloatArray(100)
            val detectionClasses = FloatArray(100)

            interpreter.runForMultipleInputsOutputs(arrayOf(inputBuffer), mapOf(
                0 to rawDetectionBoxes,
                1 to detectionScores,
                2 to detectionClasses
            ))

            val outputMap = mapOf(
                "detection_boxes" to rawDetectionBoxes[0].map { it.toList() },
                "detection_scores" to detectionScores.toList(),
                "detection_classes" to detectionClasses.toList()
            )

            result.success(outputMap)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to run model inference: ${e.message}", null)
        }
    }
}
