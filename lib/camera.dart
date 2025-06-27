import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _showCapturedImage = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      _capturedImage = await _controller.takePicture();
      setState(() => _showCapturedImage = true);

      if (_capturedImage != null) {
        final bytes = await _capturedImage!.readAsBytes();
        await _sendFrameToServer(bytes);
      }
    } catch (e) {
      print("Camera error: $e");
    }
  }

  Future<void> _sendFrameToServer(Uint8List frameData) async {
    final uri = Uri.parse('http://127.0.0.1:5000/check_face');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'frame',
        frameData,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await _askNameAndSend(frameData);
      } else {
        _showErrorDialog(responseString.replaceAll('"', ''));
      }
    } catch (e) {
      _showErrorDialog("Failed to connect to server.");
    }
  }

  Future<void> _askNameAndSend(Uint8List frameData) async {
    String name = "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Name"),
          content: TextField(
            autofocus: true,
            onChanged: (value) => name = value.trim(),
            decoration: const InputDecoration(hintText: "e.g., John"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (name.isEmpty) return;

                final uri = Uri.parse('http://127.0.0.1:5000/upload');
                final request = http.MultipartRequest('POST', uri)
                  ..fields['name'] = name
                  ..files.add(http.MultipartFile.fromBytes(
                    'frame',
                    frameData,
                    filename: '$name.jpg',
                    contentType: MediaType('image', 'jpeg'),
                  ));

                final response = await request.send();
                final responseBody = await response.stream.bytesToString();

                Navigator.of(context).pop();

                if (response.statusCode == 200) {
                  _deleteImage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ $responseBody')),
                  );
                } else {
                  _showErrorDialog(responseBody.replaceAll('"', ''));
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _deleteImage() {
    setState(() {
      _capturedImage = null;
      _showCapturedImage = false;
    });
  }

  void _goBack() {
    _controller.dispose();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 800,
                height: 600,
                child: _showCapturedImage
                    ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(
                          widget.camera.lensDirection == CameraLensDirection.front ? math.pi : 0,
                        ),
                        child: FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return CameraPreview(_controller);
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              _showCapturedImage
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _deleteImage,
                          child: const Text('Delete'),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _takePicture,
                          child: const Text('Capture Image'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _goBack,
                          child: const Text('Back'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
