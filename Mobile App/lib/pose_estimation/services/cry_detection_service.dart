import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

/// Service to interact with the Baby Cry Detection API (deploy-v2).
///
/// The API implements a two-stage audio pipeline:
/// - Stage 1: CNN binary cry detection (is it a cry?)
/// - Stage 2: Wav2Vec2+ECAPA-TDNN cry-type classification (why is baby crying?)
class CryDetectionService {
  final String baseUrl;

  CryDetectionService({required this.baseUrl});

  /// Checks if the API server is healthy and both AI models are loaded.
  ///
  /// Returns the health response map:
  /// - status: "ok"
  /// - stage1_loaded: true when CNN model is ready
  /// - stage2_loaded: true when Wav2Vec2 model is ready
  /// Returns null if the request failed.
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('Cry Detection Health check: $data');
        return data;
      } else {
        debugPrint('Cry Detection Health check failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Cry Detection Health check error: $e');
      return null;
    }
  }

  /// Sends an audio file to the Baby Cry Detection API for analysis.
  ///
  /// The server runs VAD (silence removal), then:
  /// 1. Stage 1 CNN: determines if audio contains an infant cry
  /// 2. Stage 2 (if cry detected): Wav2Vec2+ECAPA classifies the cry type
  ///
  /// Returns the parsed JSON response containing:
  /// - filename: Original filename echoed back
  /// - duration_sec: Audio duration in seconds
  /// - is_cry: Whether a cry was detected
  /// - stage1: {verdict: "cry"/"no_cry", confidence: float}
  /// - stage2: {cry_type: string, confidence: float}
  /// - processing_time_sec: Server processing time
  Future<Map<String, dynamic>?> predict(File audioFile) async {
    if (!await audioFile.exists()) {
      debugPrint("Audio file doesn't exist.");
      return null;
    }

    // Determine MIME type from file extension
    final extension = audioFile.path.split('.').last.toLowerCase();
    final mimeType = _mimeTypeForExtension(extension);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        contentType: MediaType(mimeType.$1, mimeType.$2),
      ),
    );

    try {
      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseString);
        debugPrint('Cry Detection - Audio processed successfully');
        debugPrint('Cry Detection - Response: $data');
        return data;
      } else if (response.statusCode == 503) {
        debugPrint('Cry Detection - Service unavailable (models loading): ${response.statusCode}');
        debugPrint('Response body: $responseString');
        return null;
      } else {
        debugPrint('Cry Detection - Server error: ${response.statusCode}');
        debugPrint('Response body: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cry Detection - Error sending audio: $e');
      return null;
    }
  }

  /// Maps file extensions to MIME type components.
  (String, String) _mimeTypeForExtension(String ext) {
    switch (ext) {
      case 'wav':
        return ('audio', 'wav');
      case 'mp3':
        return ('audio', 'mp3');
      case 'flac':
        return ('audio', 'flac');
      case 'ogg':
        return ('audio', 'ogg');
      case 'opus':
        return ('audio', 'ogg');
      case 'm4a':
        return ('audio', 'mp4');
      case 'aac':
        return ('audio', 'aac');
      default:
        return ('audio', 'mp4');
    }
  }

  /// Returns a user-friendly message for a given cry type.
  static String cryTypeMessage(String cryType) {
    switch (cryType.toLowerCase()) {
      case 'needs':
        return 'Baby may be hungry or wants attention.';
      case 'pain':
        return 'Baby may be in pain — check immediately.';
      case 'discomfort':
        return 'Baby may be uncomfortable — check nappy, temperature, or clothing.';
      case 'tired':
        return 'Baby is sleepy and needs rest.';
      case 'burping':
        return 'Baby may need to be burped.';
      default:
        return 'Unknown — check on baby.';
    }
  }

  /// Returns an icon for a given cry type.
  static IconData cryTypeIcon(String cryType) {
    switch (cryType.toLowerCase()) {
      case 'needs':
        return Icons.restaurant_rounded;
      case 'pain':
        return Icons.emergency_rounded;
      case 'discomfort':
        return Icons.thermostat_rounded;
      case 'tired':
        return Icons.bedtime_rounded;
      case 'burping':
        return Icons.air_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Returns a color for a given cry type.
  static Color cryTypeColor(String cryType) {
    switch (cryType.toLowerCase()) {
      case 'needs':
        return Colors.orange;
      case 'pain':
        return Colors.red;
      case 'discomfort':
        return Colors.amber;
      case 'tired':
        return Colors.purple;
      case 'burping':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

