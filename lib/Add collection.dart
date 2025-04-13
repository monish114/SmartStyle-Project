import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class ColorInfo {
  final String name;
  final int r;
  final int g;
  final int b;

  ColorInfo({required this.name, required this.r, required this.g, required this.b});
}

class AddCollection extends StatefulWidget {
  const AddCollection({Key? key}) : super(key: key);

  @override
  _AddCollectionState createState() => _AddCollectionState();
}

class _AddCollectionState extends State<AddCollection> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isUploading = false;
  String _uploadStatus = '';
  List<CameraDescription>? cameras;
  bool _isLoading = true;
  bool _isModelLoaded = false;
  String _detectedClothType = '';
  String _dominantColor = '';
  List<ColorInfo> _colorPalette = [];

  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
    _loadColorPalette();
  }

  Future<void> _loadModel() async {
    try {
      print("Loading clothing detection model...");

      _interpreter = await Interpreter.fromAsset('assets/clothdetection.tflite');

      final labelsString = await DefaultAssetBundle.of(context)
          .loadString("assets/clothdetectionlabels.txt");
      _labels = labelsString.split("\n").where((line) => line.trim().isNotEmpty).toList();

      if (_interpreter != null) {
        final inputTensor = _interpreter!.getInputTensor(0);
        final outputTensor = _interpreter!.getOutputTensor(0);
        print('Model loaded successfully');
        print('Model input shape: ${inputTensor.shape}');
        print('Model output shape: ${outputTensor.shape}');
      }
      print('Loaded labels: $_labels');

      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Failed to load model or labels: ${e.toString()}');
    }
  }


  Future<void> _loadColorPalette() async {
    try {
      final rawData = await rootBundle.loadString('assets/clothing_colors2.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawData);

      _colorPalette = csvTable.skip(1).map((row) {
        return ColorInfo(
          name: row[0].toString(),
          r: int.parse(row[1].toString()),
          g: int.parse(row[2].toString()),
          b: int.parse(row[3].toString()),
        );
      }).toList();

      print('Loaded ${_colorPalette.length} colors from the palette');
    } catch (e) {
      print('Failed to load color palette: ${e.toString()}');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      cameras = await availableCameras();
      CameraDescription backCamera = cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = 'Failed to initialize camera: ${e.toString()}';
        });
      }
      print('Camera initialization error: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _interpreter?.close();

    _controller?.dispose();
    super.dispose();
  }

  String _findClosestColor(int r, int g, int b) {
    if (_colorPalette.isEmpty) {
      return 'Unknown';
    }

    double minDistance = double.infinity;
    String closestColorName = 'Unknown';

    for (var color in _colorPalette) {
      double distance = sqrt(
          pow(r - color.r, 2) + pow(g - color.g, 2) + pow(b - color.b, 2)
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColorName = color.name;
      }
    }

    return closestColorName;
  }

  Future<String> _detectDominantColor(img.Image image) async {
    Map<int, int> colorCounts = {};

    const int sampleStep = 5;
    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);

        int simplifiedR = (pixel.r ~/ 8) * 8;
        int simplifiedG = (pixel.g ~/ 8) * 8;
        int simplifiedB = (pixel.b ~/ 8) * 8;

        int colorKey = (simplifiedR << 16) | (simplifiedG << 8) | simplifiedB;

        colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      }
    }

    int? dominantColorKey;
    int maxCount = 0;

    colorCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantColorKey = key;
      }
    });

    if (dominantColorKey != null) {
      int r = (dominantColorKey! >> 16) & 0xFF;
      int g = (dominantColorKey! >> 8) & 0xFF;
      int b = dominantColorKey! & 0xFF;

      String colorName = _findClosestColor(r, g, b);

      return '$colorName (R:$r,G:$g,B:$b)';
    }

    return 'Unknown';
  }

  Future<void> _takePictureAndUpload() async {
    if (!_isModelLoaded || _interpreter == null) {
      setState(() {
        _uploadStatus = "Model is still loading, please wait...";
      });
      return;
    }

    try {
      await _initializeControllerFuture;

      setState(() {
        _isUploading = true;
        _uploadStatus = 'Taking picture...';
      });

      await _controller!.setFlashMode(FlashMode.off);

      final XFile image = await _controller!.takePicture();
      print('Picture taken: ${image.path}');

      setState(() {
        _uploadStatus = 'Processing image...';
      });

      await _processImage(File(image.path));

      final fileName = path.basename(image.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final databaseRef = FirebaseDatabase.instance.ref().child('clothing_items').push();
      print('Creating database entry with reference: ${databaseRef.path}');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _uploadStatus = "User not authenticated!";
        });
        return;
      }

      await databaseRef.set({
        'userId': user.uid,
        'localPath': image.path,
        'timestamp': timestamp,
        'filename': fileName,
        'clothType': _detectedClothType,
        'dominantColor': _dominantColor,
        'uploadTime': DateTime.now().toString(),
      });
      print('Data saved to Realtime Database with key: ${databaseRef.key}');

      setState(() {
        _isUploading = false;
        _uploadStatus = 'Item data saved successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item saved! Detected: $_detectedClothType, Color: $_dominantColor')),
      );
    } catch (e) {
      print('Save error: ${e.toString()}');
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: ${e.toString()}')),
      );
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      setState(() {
        _uploadStatus = 'Analyzing cloth type...';
      });

      final imageData = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageData);

      if (decodedImage == null) {
        setState(() {
          _detectedClothType = 'Failed to decode image';
        });
        return;
      }

      _dominantColor = await _detectDominantColor(decodedImage);
      print('Detected dominant color: $_dominantColor');

      final resizedImage = img.copyResize(
        decodedImage,
        width: 256,
        height: 256,
      );

      var inputData = Float32List(1 * 256 * 256 * 3);
      int index = 0;

      for (var y = 0; y < resizedImage.height; y++) {
        for (var x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputData[index++] = pixel.r / 255.0;
          inputData[index++] = pixel.g / 255.0;
          inputData[index++] = pixel.b / 255.0;
        }
      }

      var reshapedInput = inputData.reshape([1, 256, 256, 3]);

      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      print('Running inference...');
      _interpreter!.run(reshapedInput, output);
      print('Inference completed');

      int maxIndex = 0;
      double maxConfidence = output[0][0];

      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > maxConfidence) {
          maxConfidence = output[0][i];
          maxIndex = i;
        }
      }

      String clothType = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
      double confidencePercentage = maxConfidence * 100;

      print('Detected cloth type: $clothType with confidence: $confidencePercentage%');

      setState(() {
        _detectedClothType = '$clothType (${confidencePercentage.toStringAsFixed(1)}%)';
        _uploadStatus = 'Detected: $_detectedClothType, Color: $_dominantColor';
      });
    } catch (e) {
      print('Error during cloth detection: ${e.toString()}');
      setState(() {
        _detectedClothType = 'Detection error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clothing Detection & Upload')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _controller != null
                ? CameraPreview(_controller!)
                : Center(
              child: Text('Failed to initialize camera'),
            ),
          ),
          if (_detectedClothType.isNotEmpty && !_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Last detected: $_detectedClothType',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_dominantColor.isNotEmpty)
                    Text(
                      'Color: $_dominantColor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(_uploadStatus),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isLoading || _isUploading) ? null : _takePictureAndUpload,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}