import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'main.dart';
import 'Mood Collection Page.dart';

class MoodDetector extends StatefulWidget {
  @override
  State<MoodDetector> createState() => _MoodDetectorState();
}

class _MoodDetectorState extends State<MoodDetector> {
  CameraController? _cameraController;
  bool isCameraLoaded = false;
  String detectedMood = "Detecting Mood...";
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadModel());
  }

  void _initCamera() async {
    try {
      CameraDescription frontCamera = cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        isCameraLoaded = true;
      });
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  Future<void> _loadModel() async {
    try {
      print("Loading model...");
      _interpreter = await Interpreter.fromAsset("assets/detectemotions.tflite");
      final labelsString = await DefaultAssetBundle.of(context)
          .loadString("assets/detectemotionslabels.txt");
      _labels = labelsString.split("\n").where((line) => line.trim().isNotEmpty).toList();
      print("Model Loaded Successfully!");
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _captureAndDetect() async {
    if (!_modelLoaded || _interpreter == null) {
      return;
    }
    try {
      XFile imageFile = await _cameraController!.takePicture();
      await _processImage(File(imageFile.path));
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _processImage(File image) async {
    try {
      img.Image? imageInput = img.decodeImage(await image.readAsBytes());
      if (imageInput == null) return;
      img.Image grayImage = img.grayscale(imageInput);
      img.Image resizedImage = img.copyResize(grayImage, width: 48, height: 48);
      Float32List input = Float32List(48 * 48);
      int index = 0;

      for (int y = 0; y < 48; y++) {
        for (int x = 0; x < 48; x++) {
          input[index++] = resizedImage.getPixel(x, y).r / 255.0;
        }
      }
      var reshapedInput = input.reshape([1, 48, 48, 1]);
      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(reshapedInput, output);

      int highestIndex = output[0].indexOf(output[0].reduce((double a, double b) => a > b ? a : b));
      setState(() {
        detectedMood = _labels[highestIndex];
        print("Detected Mood Checker: $detectedMood");
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MoodCollectionPage(mood: detectedMood),
        ),
      );
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mood Detection")),
      body: Column(
        children: [
          Expanded(
            child: isCameraLoaded
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _captureAndDetect,
              child: Text("📷 Capture and Detect"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}