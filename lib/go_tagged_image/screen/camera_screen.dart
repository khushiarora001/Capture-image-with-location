// camera_screen.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_assement/constants/string_constant.dart';
import 'package:camera_assement/go_tagged_image/provider/translator_provider.dart';
import 'package:camera_assement/go_tagged_image/screen/widget/location_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:provider/provider.dart';
import 'package:camera_assement/go_tagged_image/provider/camera_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/location_provider.dart';
import 'package:camera_assement/go_tagged_image/screen/preview_screen.dart';
import 'package:translator/translator.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  String _translatedLocation = '';
  final GoogleTranslator translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    // Ask for camera and location permissions, and fetch camera + location if granted
    await cameraProvider.requestCameraPermission();
    await locationProvider.requestLocationPermission();

    if (cameraProvider.cameraPermissionGranted &&
        locationProvider.locationPermissionGranted) {
      await cameraProvider.initializeCamera();
      await locationProvider.fetchLocation();
      final fetchedLocation = locationProvider.location;

      if (fetchedLocation.isNotEmpty) {
        _translatedLocation = fetchedLocation;
        await Provider.of<TranslationProvider>(
          context,
          listen: false,
        ).translateText(locationProvider.location);
        (_translatedLocation);
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          final retryLocation = locationProvider.location;
          if (retryLocation.isNotEmpty) {
            _translatedLocation = retryLocation;
            Provider.of<TranslationProvider>(
              context,
              listen: false,
            ).translateText(locationProvider.location);
            (_translatedLocation);
          }
        });
      }
    }
  }

  Future<void> _imageCapture(
    BuildContext context,
    CameraController controller,
    String translatedText,
  ) async {
    XFile file = await controller.takePicture();
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: cropImageTitle),
        IOSUiSettings(title: cropImageTitle),
      ],
    );
    if (croppedFile == null) return;

    final imagebyte = await File(croppedFile.path).readAsBytes();
    // Navigate to the preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PreviewScreen(
              imageBytes: imagebyte,
              locationText: translatedText,
            ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: Consumer3<CameraProvider, LocationProvider, TranslationProvider>(
        builder: (
          context,
          cameraProvider,
          locationProvider,
          translationProvider,
          child,
        ) {
          if (cameraProvider.cameraPermissionDenied) {
            return const Center(
              child: Text(
                cameraPermissionDenied,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (locationProvider.locationPermissionDenied) {
            return const Center(
              child: Text(
                locationPermissionDenied,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!cameraProvider.cameraAccessallow ||
              !locationProvider.locationAccess) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              CameraPreview(cameraProvider.controller!),

              translationProvider.translatedText.isEmpty
                  ? const Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: LocationContainerWidget(
                      locationText: translationProvider.translatedText,
                    ),
                  ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed:
                      () => _imageCapture(
                        context,
                        cameraProvider.controller!,
                        translationProvider.translatedText,
                      ),
                  child: const Text(appTitle),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
