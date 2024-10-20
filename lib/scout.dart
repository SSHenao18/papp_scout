import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  String? httptext;
  String? locationtext;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
        child: Column(
          children: [
            if (_isCameraInitialized)
              AspectRatio(
                aspectRatio: (12.0 / 16.0),
                child: CameraPreview(_controller!),
              )
            else
              Center(child: CircularProgressIndicator()),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<Position>(
                  future: _determinePosition(),
                  builder: (context, snapshot) {
                    locationtext = 'Unable to get location';
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      locationtext = 'Error: ${snapshot.error}';
                    } else if (snapshot.hasData) {
                      final position = snapshot.data!;
                      locationtext =
                          'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
                    }
                    return Text(locationtext!);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_controller != null && _controller!.value.isInitialized) {
                  try {
                    await _controller!.takePicture();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Picture taken!')),
                    );
                  } catch (e) {
                    print(e);
                  }
                }
              },
              child: Text('Capture'),
            ),
            SizedBox(height: 20),
            Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(httptext ?? 'No data')),
            ElevatedButton(
                onPressed: () async {
                  // Get data from xmlrpc
                  final url =
                      Uri.parse('http://127.0.0.1:8000/api/categorias/');
                  // xml_rpc.call(url, 'version', []).then((result) {
                  //   if (result['server_version'] is String) {
                  //     httptext = result['server_version'];
                  //   }
                  http.get(url).then((response) {
                    print("Got response");
                    httptext = jsonDecode(response.body).toString();
                    setState(() {});
                  });
                },
                child: Text('Get data from xmlrpc'))
          ],
        ),
      ),
    );
  }
}
