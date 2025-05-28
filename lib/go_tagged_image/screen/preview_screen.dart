import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera_assement/constants/string_constant.dart';
import 'package:camera_assement/go_tagged_image/provider/save_provider.dart';
import 'package:camera_assement/go_tagged_image/screen/widget/location_wisget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:provider/provider.dart';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';

class PreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String locationText;

  const PreviewScreen({
    super.key,
    required this.imageBytes,
    required this.locationText,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> saveIntoGallery(
    GlobalKey repaintKey,
    BuildContext context,
  ) async {
    try {
      RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      // we use different package for android and ios becuase savergallery package doesn't support android 8 version  and gallery saver not able to find the temp  location in ios
      bool success = false;
      if (Platform.isIOS) {
        final result = await SaverGallery.saveImage(
          pngBytes,
          quality: 100,
          fileName: "Image",
          skipIfExists: false,
        );
        success = result.isSuccess;
      } else {
        // Temporary file
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        success =
            await GallerySaver.saveImage(file.path, albumName: "Image") ??
            false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success == true
                  ? ' Image saved to gallery'
                  : 'Failed to save image',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(' Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(previewTitle),
        actions: [
          // Save button on the AppBar - disabled while saving
          Consumer<SaveProvider>(
            builder: (context, saveProvider, child) {
              return Padding(
                padding: EdgeInsets.fromLTRB(20, 2, 20, 2),
                child: ElevatedButton(
                  onPressed:
                      () =>
                          saveProvider.isSaving
                              ? () {}
                              : saveIntoGallery(_globalKey, context),
                  child: const Text(saveImage),
                ),
              );
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          children: [
            Image.memory(
              widget.imageBytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Overlay location text on image
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: LocationContainerWidget(locationText: widget.locationText),
            ),
          ],
        ),
      ),
    );
  }
}
