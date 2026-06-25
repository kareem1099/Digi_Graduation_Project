import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.orangeAccent;

    for (final pose in poses) {
      // 1. Draw connections between landmarks (Skeleton)
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paint) {
        final landmark1 = pose.landmarks[type1];
        final landmark2 = pose.landmarks[type2];

        if (landmark1 != null && landmark2 != null) {
          canvas.drawLine(
            Offset(
              translateX(landmark1.x, rotation, size, absoluteImageSize),
              translateY(landmark1.y, rotation, size, absoluteImageSize),
            ),
            Offset(
              translateX(landmark2.x, rotation, size, absoluteImageSize),
              translateY(landmark2.y, rotation, size, absoluteImageSize),
            ),
            paint,
          );
        }
      }

      // Draw Torso
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);

      // Draw Arms (Left)
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);

      // Draw Arms (Right)
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      // Draw Legs (Left)
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);

      // Draw Legs (Right)
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      // 2. Draw dots on each landmark
      for (final type in pose.landmarks.keys) {
        final landmark = pose.landmarks[type];
        if (landmark != null) {
          canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            4,
            Paint()..color = Colors.white,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }

  /// Translates the X coordinate from images space to canvas space.
  double translateX(
    double x,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / absoluteImageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / absoluteImageSize.height;
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  /// Translates the Y coordinate from image space to canvas space.
  double translateY(
    double y,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}
