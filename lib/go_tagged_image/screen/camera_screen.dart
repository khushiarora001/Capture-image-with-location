// camera_screen.dart (Final Version: Optimized location UI + Capture after Crop + Gallery Save)
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

import 'package:provider/provider.dart';
import 'package:camera_assement/constants/string_constant.dart';
import 'package:camera_assement/go_tagged_image/provider/translator_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/location_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/camera_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final GlobalKey _repaintKey = GlobalKey();
  String _translatedLocation = '';
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final translatorProvider = Provider.of<TranslationProvider>(
      context,
      listen: false,
    );

    await cameraProvider.requestCameraPermission();
    await locationProvider.requestLocationPermission();

    if (cameraProvider.cameraPermissionGranted &&
        locationProvider.locationPermissionGranted) {
      await cameraProvider.initializeCamera(_isFrontCamera);
      await locationProvider.fetchLocation();

      final loc = locationProvider.location;
      _translatedLocation = loc;
      await translatorProvider.translateText(loc);
    }
  }

  Future<void> _captureAndSave() async {
    try {
      final controller =
          Provider.of<CameraProvider>(context, listen: false).controller!;
      final file = await controller.takePicture();
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop Image'),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );
      if (croppedFile == null) return;

      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image overlayImage = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await overlayImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final overlayBytes = byteData!.buffer.asUint8List();

      final baseBytes = await File(croppedFile.path).readAsBytes();
      final ui.Codec baseCodec = await ui.instantiateImageCodec(baseBytes);
      final ui.FrameInfo baseFrame = await baseCodec.getNextFrame();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImage(baseFrame.image, Offset.zero, Paint());
      final overlayCodec = await ui.instantiateImageCodec(overlayBytes);
      final overlayFrame = await overlayCodec.getNextFrame();
      final double overlayTop =
          baseFrame.image.height.toDouble() -
          overlayFrame.image.height.toDouble();
      canvas.drawImage(overlayFrame.image, Offset(0, overlayTop), Paint());

      final finalImage = await recorder.endRecording().toImage(
        baseFrame.image.width,
        baseFrame.image.height,
      );
      final resultBytes = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final savedBytes = resultBytes!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/geo_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(savedBytes);
      await GallerySaver.saveImage(path, albumName: "GeoTagged");

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Saved to gallery')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  void _flipCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.initializeCamera(_isFrontCamera);
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
      await cameraProvider.initializeCamera(_isFrontCamera);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,

          child:
          //   return SafeArea(
          //     bottom: false,
          //     child: Scaffold(
          Consumer3<CameraProvider, LocationProvider, TranslationProvider>(
            builder: (
              context,
              cameraProvider,
              locationProvider,
              translationProvider,
              _,
            ) {
              final now = DateTime.now();
              final formattedTime =
                  '${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute}';
              final String translatedText =
                  translationProvider.translatedText.isNotEmpty
                      ? translationProvider.translatedText
                      : _translatedLocation;

              return Stack(
                children: [
                  CameraPreview(cameraProvider.controller!),
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(10),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Camera',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 120,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: const DecorationImage(
                                        image: AssetImage(
                                          'assets/jpg/images (1).jpeg',
                                        ), // update path
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 120,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            "$translatedText",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontFamilyFallback: [
                                                'NotoSansDevanagari',
                                                'Roboto',
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 20,
                    child: FloatingActionButton(
                      heroTag: 'flip',
                      onPressed: _flipCamera,
                      child: const Icon(Icons.flip_camera_android),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      color: Colors.black.withOpacity(0.6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 🔍 Zoom Options
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildZoomOption("0.6X", 0.6),
                              _buildZoomOption("1X", 1.0),
                              _buildZoomOption("2X", 2.0),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 🎥 Capture and Flip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.flip_camera_android,
                                  color: Colors.white,
                                ),
                                onPressed: _flipCamera,
                              ),
                              Container(
                                height: 70,
                                width: 70,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                  ),
                                  onPressed: _captureAndSave,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // open gallery or collection screen
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          // 🏷️ Labels (like PHOTO selected)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLabel("PHOTO", true),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildZoomOption(String label, double zoom) {
    return GestureDetector(
      onTap: () {
        //   final controller =
        //   Provider.of<CameraProvider>(context, listen: false).controller!;
        // controller.setZoomLevel(zoom);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool selected) {
    return Text(
      text,
      style: TextStyle(
        color: selected ? Colors.yellow : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
