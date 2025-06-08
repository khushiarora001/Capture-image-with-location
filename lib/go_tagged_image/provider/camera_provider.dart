import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _controller;
  CameraController? get controller => _controller;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _cameraAccessAllow = false;
  bool get cameraAccessallow => _cameraAccessAllow;

  Future<void> initializeCamera([bool isFrontCamera = false]) async {
    final cameras = await availableCameras();
    final selectedCamera =
        isFrontCamera
            ? cameras.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.front,
            )
            : cameras.firstWhere(
              (cam) => cam.lensDirection == CameraLensDirection.back,
            );

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    notifyListeners();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initializeCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.dispose();

      _controller = null;
    }
  }

  bool cameraPermissionGranted = false;
  bool cameraPermissionDenied = false;

  Future<void> requestCameraPermission() async {
    if (Platform.isIOS) {
      cameraPermissionGranted = true;
      notifyListeners();
    } else {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final newStatus = await Permission.camera.request();
        if (newStatus.isGranted) {
          cameraPermissionGranted = true;
        } else {
          cameraPermissionDenied = true;
        }
      } else {
        cameraPermissionGranted = true;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}


  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (state == AppLifecycleState.resumed) {
  //     final PermissionStatus status = await Permission.camera.status;
  //   Print('Lifecycle resumed. Camera permission: $status');

  //     if (status.isGranted) {
  //       await _reinitializeController();
  //     } else {
  //   
  //     
  //       _errorMessage = 'Camera permission not granted';
  //       notifyListeners();
  //     }
  //   } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
  //     _controller?.dispose();
  //     _initialized = false;
  //  Print('Camera disposed due to lifecycle: $state');
  //   }
  // }

