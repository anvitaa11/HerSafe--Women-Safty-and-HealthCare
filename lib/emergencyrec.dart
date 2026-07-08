/*import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class EmergencyRecording extends StatefulWidget {
  const EmergencyRecording({super.key});

  @override
  State<EmergencyRecording> createState() => _EmergencyRecordingState();
}

class _EmergencyRecordingState extends State<EmergencyRecording> {

  CameraController? controller;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {

    final cameras = await availableCameras();

    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );

    await controller!.initialize();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> startRecording() async {

    if (controller != null && !controller!.value.isRecordingVideo) {

      await controller!.startVideoRecording();

      setState(() {
        isRecording = true;
      });

    }
  }

  Future<void> stopRecording() async {

    if (controller != null && controller!.value.isRecordingVideo) {

      final file = await controller!.stopVideoRecording();

      setState(() {
        isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Video saved: ${file.path}")),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Emergency Recording"),
        backgroundColor: Colors.pink,
      ),

      body: Column(
        children: [

          Expanded(
            child: CameraPreview(controller!),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 15,
              ),
            ),
            onPressed: () {
              if (isRecording) {
                stopRecording();
              } else {
                startRecording();
              }
            },
            child: Text(
              isRecording ? "Stop Recording" : "Start Recording",
              style: const TextStyle(fontSize: 18),
            ),
          ),

          const SizedBox(height: 30)

        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

 */