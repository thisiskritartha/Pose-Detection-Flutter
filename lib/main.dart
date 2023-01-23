import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? img;
  late ImagePicker picker;
  dynamic poseDetector;
  late final List<Pose> poses;
  dynamic image;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    final options = PoseDetectorOptions(
        mode: PoseDetectionMode.single, model: PoseDetectionModel.base);
    poseDetector = PoseDetector(options: options);
  }

  @override
  void dispose() {
    super.dispose();
  }

  imgFromGallery() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    img = File(image!.path);
    doPoseDetection();
  }

  imgFromCamera() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    img = File(image!.path);
    doPoseDetection();
  }

  doPoseDetection() async {
    InputImage inputImage = InputImage.fromFile(img!);
    poses = await poseDetector.processImage(inputImage);
    for (Pose pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        final type = landmark.type;
        final x = landmark.x;
        final y = landmark.y;
        print('${type.name} 💥 $x  $y');
      });
    }
    setState(() {
      img;
    });
    drawPose();
  }

  drawPose() async {
    image = await img!.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image;
      poses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage(
                'images/bg.jpg',
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(width: double.infinity),
              Container(
                margin: const EdgeInsets.only(top: 100),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.transparent,
                        primary: Colors.transparent,
                      ),
                      onPressed: imgFromGallery,
                      onLongPress: imgFromCamera,
                      child: img == null
                          ? Container(
                              height: 380,
                              width: 350,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 100,
                                color: Colors.white,
                              ),
                            )
                          : Center(
                              child: FittedBox(
                                child: SizedBox(
                                  width: image.width.toDouble(),
                                  height: image.height.toDouble(),
                                  child: CustomPaint(
                                    painter: PosePainter(poses, image),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.image);
  dynamic image;
  List<Pose> poses;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = Colors.blueAccent;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(Offset(landmark.x, landmark.y), 1, paint);
      });

      //For Drawing the Line
      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(joint1.x, joint1.y), Offset(joint2.x, joint2.y), paintType);
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      //Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
