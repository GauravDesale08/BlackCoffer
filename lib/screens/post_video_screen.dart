import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../utils/colors.dart';
import '../resources/firestore_methods.dart';
import '../utils/global_variables.dart';

class PostVideoScreen extends StatefulWidget {
  const PostVideoScreen({Key? key}) : super(key: key);

  @override
  State<PostVideoScreen> createState() => _PostVideoScreenState();
}

class _PostVideoScreenState extends State<PostVideoScreen> {
  Position? _currentPosition;
  String? _currentCity;
  bool _isLocation = false;
  bool _isLoading = false;
  XFile? pickedFile = null;
  String downloadURL = "";

  TextEditingController _locationController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  VideoPlayerController? _videoController;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickVideoFromCamera() async {
    pickedFile = await _imagePicker.pickVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _videoController = VideoPlayerController.file(File(pickedFile!.path))
          ..initialize().then((_) {
            // Ensure that the video starts playing once it's initialized
            _videoController!.play();
          });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocation = true;
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _getCurrentCity(position.latitude, position.longitude);
      });
    } catch (e) {
      showSnackBar(context, e.toString());
      setState(() {
        _isLocation = false;
      });
    }
  }

  Future<void> _getCurrentCity(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentCity = placemarks[0].locality ?? ""; // Get locality if available, else set empty string
          _locationController.text = _currentCity!; // Set only the city name
          _isLocation = false;
        });
      }
    } catch (e) {
      showSnackBar(context, e.toString());
      setState(() {
        _isLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: colorPrimary),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Post Video",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          backgroundColor: colorPrimary,
          actions: [
            GestureDetector(
              onTap: _pickVideoFromCamera,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(
                  Icons.video_call_rounded,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
        body: _isLocation
            ? Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorPrimary,
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextField(
                          keyboardType: TextInputType.text,
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            label: const Text("Video Title"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          keyboardType: TextInputType.text,
                          controller: _descController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            label: const Text("Video Description"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          controller: _locationController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            label: const Text("Video Location"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          controller: _categoryController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            label: const Text("Video category"),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 500,
                          child: _videoController != null
                              ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_videoController!),
                                VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                ),
                                VideoControlsOverlay(controller: _videoController!)
                              ],
                            ),
                          )
                              : const Center(child: Text('No video selected')),
                        ),
                        const SizedBox(
                          height: 26,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_titleController.text.isEmpty) {
                                  showSnackBar(context, "Enter title");
                                } else if (_descController.text.isEmpty) {
                                  showSnackBar(context, "Enter description");
                                } else if (_locationController.text.isEmpty) {
                                  showSnackBar(context, "Enter location");
                                } else if (_categoryController.text.isEmpty) {
                                  showSnackBar(context, "Enter category");
                                } else if (pickedFile == null) {
                                  showSnackBar(context, "Pick Video");
                                } else {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  final file = File(pickedFile!.path);
                                  final firebaseStorageRef =
                                  firebase_storage.FirebaseStorage.instance.ref().child('videos').child(
                                    '${DateTime.now().microsecondsSinceEpoch}.mp4',
                                  ); // Provide a unique filename

                                  final uploadTask = firebaseStorageRef.putFile(file);

                                  await uploadTask.whenComplete(() async {
                                    showSnackBar(context, "'Video uploaded successfully'");
                                    downloadURL = await firebaseStorageRef.getDownloadURL();

                                    try {
                                      await FireStoreMethods().postVideo(
                                        title: _titleController.text.trim(),
                                        des: _descController.text.trim(),
                                        location: _locationController.text.trim(),
                                        category: _categoryController.text.trim(),
                                        url: downloadURL,
                                      );
                                    } on Exception catch (e) {
                                      showSnackBar(context, e.toString());
                                    }

                                    setState(() {
                                      _isLoading = false;
                                    });
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              )
                                  : Text(
                                "Post",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Navigate back to the previous screen (HomeScreen)
                          },
                          child: Text(
                            'Back to Home',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoControlsOverlay extends StatelessWidget {
  final VideoPlayerController? controller;

  const VideoControlsOverlay({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (controller!.value.isPlaying) {
          controller!.pause();
        } else {
          controller!.play();
        }
      },
      child: Stack(
        children: [
          const SizedBox.expand(),
          Align(
            alignment: Alignment.center,
            child: Icon(
              controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
