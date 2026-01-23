import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/services/cloudinary_service.dart';
import 'package:cocpit_app/services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  File? _file;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isUploading = false;

  Future<void> _pickMedia(bool video) async {
    final XFile? picked = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _file = File(picked.path);
        _isVideo = video;
      });

      if (video) {
         _videoController?.dispose();
         _videoController = VideoPlayerController.file(_file!)
            ..initialize().then((_) {
               setState(() {});
               _videoController!.play();
               _videoController!.setLooping(true);
            });
      }
    }
  }

  Future<void> _submit() async {
     if (_file == null) return;

     setState(() => _isUploading = true);

     try {
        final url = await CloudinaryService.uploadFile(_file!, isVideo: _isVideo);

        await StoryService.createStory(
           title: _titleController.text,
           description: _descController.text,
           mediaUrl: url,
        );

        if (mounted) {
           Navigator.pop(context, true); // Return true to refresh
        }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
           setState(() => _isUploading = false);
        }
     }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Story"),
        actions: [
           if (_file != null && !_isUploading)
             IconButton(onPressed: _submit, icon: const Icon(Icons.check))
        ],
      ),
      body: _isUploading
         ? const Center(child: CircularProgressIndicator())
         : SingleChildScrollView(
             child: Column(
               children: [
                  if (_file == null)
                     Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: Center(
                           child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 ElevatedButton.icon(
                                    onPressed: () => _pickMedia(false),
                                    icon: const Icon(Icons.image),
                                    label: const Text("Image")
                                 ),
                                 const SizedBox(width: 20),
                                 ElevatedButton.icon(
                                    onPressed: () => _pickMedia(true),
                                    icon: const Icon(Icons.videocam),
                                    label: const Text("Video")
                                 ),
                              ],
                           ),
                        ),
                     )
                  else
                     SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: _isVideo
                           ? (_videoController != null && _videoController!.value.isInitialized
                               ? AspectRatio(
                                   aspectRatio: _videoController!.value.aspectRatio,
                                   child: VideoPlayer(_videoController!),
                                 )
                               : const Center(child: CircularProgressIndicator()))
                           : Image.file(_file!, fit: BoxFit.cover),
                     ),

                  if (_file != null)
                     Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                           children: [
                              TextField(
                                 controller: _titleController,
                                 decoration: const InputDecoration(labelText: "Title (Optional)"),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                 controller: _descController,
                                 decoration: const InputDecoration(labelText: "Description (Optional)"),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                 onPressed: () {
                                    setState(() {
                                       _file = null;
                                       _videoController?.dispose();
                                       _videoController = null;
                                    });
                                 },
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                 child: const Text("Remove Media")
                              )
                           ],
                        ),
                     )
               ],
             ),
         ),
    );
  }
}
