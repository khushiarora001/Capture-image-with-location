import 'package:camera_assement/constants/string_constant.dart';
import 'package:camera_assement/go_tagged_image/provider/camera_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/location_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/save_provider.dart';
import 'package:camera_assement/go_tagged_image/provider/translator_provider.dart';
import 'package:camera_assement/go_tagged_image/screen/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SaveProvider()),

        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      home: const CameraScreen(),
    );
  }
}
