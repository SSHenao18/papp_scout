import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:papp_scout/common/scout.dart';
import 'package:papp_scout/services/http_upload_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  TextEditingController? _nameController;
  final HttpUploadService _httpUploadService = HttpUploadService();
  String? httptext;
  double? latitude;
  double? longitude;
  String? locationtext;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _nameController = TextEditingController();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController?.dispose();
    super.dispose();
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When permissions are granted, get the position
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_isCameraInitialized)
              AspectRatio(
                aspectRatio: (11.0 / 16.0),
                child: CameraPreview(_controller!),
              )
            else
              Center(child: CircularProgressIndicator()),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_controller != null && _controller!.value.isInitialized) {
                  try {
                    XFile img = await _controller!.takePicture();
                    String imgpath = img.path;
                    Position position = await _determinePosition();
                    Scout scout = Scout(
                      name: _nameController?.text ?? 'Unknown',
                      latitude: position.latitude,
                      longitude: position.longitude,
                      image: imgpath,
                    );

                    _httpUploadService.uploadScout(scout);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Picture taken and uploaded!\n Name: ${scout.name}\n Latitude: ${scout.latitude}\n Longitude: ${scout.longitude}\n")),
                    );
                    setState(() {
                      httptext = _nameController?.text;
                    });
                  } catch (e) {
                    print(e);
                  }
                }
              },
              child: Text('Capture'),
            ),
          ],
        ),
      ),
    );
  }
}
