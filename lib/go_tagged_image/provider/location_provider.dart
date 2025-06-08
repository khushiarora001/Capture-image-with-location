// location_provider.dart
import 'dart:io';

import 'package:flutter/foundation.dart' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:translator/translator.dart';

class LocationProvider with ChangeNotifier {
  String _location = 'Fetch locatiom';
  String get location => _location;

  bool _locationAccess = false;
  bool get locationAccess => _locationAccess;

  bool locationPermissionGranted = false;
  bool locationPermissionDenied = false;

  Future<void> requestLocationPermission() async {
    if (Platform.isIOS) {
      locationPermissionGranted = true;
      notifyListeners();
    } else {
      final status = await Permission.location.status;
      if (!status.isGranted) {
        final newStatus = await Permission.location.request();
        if (newStatus.isGranted) {
          locationPermissionGranted = true;
        } else {
          locationPermissionDenied = true;
        }
      } else {
        locationPermissionGranted = true;
      }
      notifyListeners();
    }
  }

  Future<void> fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _location = 'Please enable location services.';
        _locationAccess = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _location = 'Please allow location access.';
        _locationAccess = false;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _location = 'Location access permanently denied.';
        _locationAccess = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks[0];
      final nowLocal = DateTime.now();
      final nowUTC = DateTime.now().toUtc();
      final localTime = DateFormat("yyyy-MM-dd HH:mm").format(nowLocal);
      final gmtTime = DateFormat("HH:mm").format(nowUTC);

      final rawLocation =
          '${place.name}, ${place.street}, ${place.locality}'
          ' ${place.postalCode}, ${place.country}\n'
          'Lat: ${position.latitude.toStringAsFixed(6)}°, Lon: ${position.longitude.toStringAsFixed(6)}°\n'
          ' $localTime GMT+ $gmtTime';
      // final rawAddress =
      //     '${place.name}, ${place.street}, ${place.subLocality}, ${place.locality}, '
      //     '${place.administrativeArea}, ${place.postalCode}, ${place.country}';
      // Get device language code (e.g., 'hi' for Hindi, 'ta' for Tamil)
      final deviceLangCode = ui.PlatformDispatcher.instance.locale.languageCode;

      // // Translate
      // final translator = GoogleTranslator();
      // final translated = await translator.translate(
      //   rawAddress,
      //   to: deviceLangCode,
      // );

      _location = rawLocation;
      _locationAccess = true;
      notifyListeners();
    } catch (e) {
      _location = 'Location access failed. Try again.';
      _locationAccess = false;
      notifyListeners();
    }
  }
}
