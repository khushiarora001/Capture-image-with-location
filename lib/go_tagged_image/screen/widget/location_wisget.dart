// shared/location_info_widget.dart
import 'package:flutter/material.dart';

class LocationContainerWidget extends StatelessWidget {
  final String locationText;
  final double imageHeight;
  final double imageWidth;

  const LocationContainerWidget({
    super.key,
    required this.locationText,
    this.imageHeight = 150,
    this.imageWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imageHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              "assets/jpg/images (1).jpeg",
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.map, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                locationText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
