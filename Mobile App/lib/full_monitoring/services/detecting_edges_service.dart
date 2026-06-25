import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

class ContourService {
  final String baseUrl;

  ContourService({required this.baseUrl});

  /// Checks if the API server is healthy and the model is loaded.
  /// Returns the health response map, or null if the request failed.
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('Health check: $data');
        return data;
      } else {
        debugPrint('Health check failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Health check error: $e');
      return null;
    }
  }

  /// Sends a video file to the Nani AI Segmentation API for processing.
  /// The API extracts the first frame and runs the DeepLabV3+ResNet-101 model.
  ///
  /// Returns the parsed JSON response containing:
  /// - contour: List of normalized [x, y] pairs in [0.0, 1.0]
  /// - corners: Key corner points, also normalized
  /// - original_size: [width, height] of the original video frame
  Future<Map<String, dynamic>?> sendVideo(File videoFile) async {
    if (!await videoFile.exists()) {
      debugPrint("Video file doesn't exist.");
      return null;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/process-video'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        videoFile.path,
        contentType: MediaType('video', 'mp4'),
      ),
    );

    try {
      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseString);
        debugPrint('Video processed successfully');
        debugPrint('Response: $data');
        return data;
      } else {
        debugPrint('Server error: ${response.statusCode}');
        debugPrint('Response body: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Error sending video: $e');
      return null;
    }
  }

  /// Parses the contour data from the API response.
  ///
  /// The API returns normalized coordinates in [0.0, 1.0] relative to the
  /// original video frame. These are scaled to the display dimensions.
  ///
  /// [contourJson] - The "contour" field from the API response.
  /// [displayWidth] - Width of the display area to scale coordinates to.
  /// [displayHeight] - Height of the display area to scale coordinates to.
  List<Offset> parseContour(
    dynamic contourJson,
    double displayWidth,
    double displayHeight,
  ) {
    if (contourJson is! List || contourJson.isEmpty) {
      debugPrint('Contour is empty or invalid');
      return [];
    }

    debugPrint('=== PARSING CONTOUR (Normalized Coords) ===');
    debugPrint('Display size: ${displayWidth}x$displayHeight');
    debugPrint('Raw points: ${contourJson.length}');

    final points = contourJson.map<Offset>((point) {
      final normalizedX = (point[0] as num).toDouble();
      final normalizedY = (point[1] as num).toDouble();
      return Offset(normalizedX * displayWidth, normalizedY * displayHeight);
    }).toList();

    if (points.isNotEmpty) {
      final minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      final maxX = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      final minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final maxY = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

      debugPrint(
          'Result range X: ${minX.toStringAsFixed(1)} to ${maxX.toStringAsFixed(1)} (display: 0-$displayWidth)');
      debugPrint(
          'Result range Y: ${minY.toStringAsFixed(1)} to ${maxY.toStringAsFixed(1)} (display: 0-$displayHeight)');
    }

    return points;
  }

  /// Parses the corners data from the API response.
  ///
  /// The API returns normalized coordinates in [0.0, 1.0] relative to the
  /// original video frame. These are scaled to the display dimensions.
  ///
  /// [cornersJson] - The "corners" field from the API response.
  /// [displayWidth] - Width of the display area to scale coordinates to.
  /// [displayHeight] - Height of the display area to scale coordinates to.
  List<Offset> parseCorners(
    dynamic cornersJson,
    double displayWidth,
    double displayHeight,
  ) {
    if (cornersJson is! List || cornersJson.isEmpty) {
      debugPrint('Corners is empty or invalid');
      return [];
    }

    debugPrint('=== PARSING CORNERS (Normalized Coords) ===');

    final corners = cornersJson.map<Offset>((point) {
      final normalizedX = (point[0] as num).toDouble();
      final normalizedY = (point[1] as num).toDouble();
      final x = normalizedX * displayWidth;
      final y = normalizedY * displayHeight;
      debugPrint(
          'Corner: Normalized($normalizedX, $normalizedY) -> Display(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})');
      return Offset(x, y);
    }).toList();

    return corners;
  }
}
