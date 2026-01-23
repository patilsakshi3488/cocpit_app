import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/feed_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Enum to track current step
  // 0: Compose (Text + Media Picker)
  // 1: Edit Image (Zoom, Ratio, Filter?) - For simplicity, just Zoom/Ratio
  // 2: Preview (Final check)
  int _currentStep = 0;

  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedFiles = [];
  String? _mediaType; // 'image' or 'video'
  bool _isPosting = false;

  // Image Editor State
  int _currentImageIndex = 0;
  double _zoomLevel = 1.0;
  int _aspectRatioIndex = 0; // 0: 1:1, 1: 4:5, 2: 16:9
  final List<double> _ratios = [1.0, 4 / 5, 16 / 9];
  final List<String> _ratioLabels = ["1:1", "4:5", "16:9"];

  // Poll Data
  bool _showPollCreator = false;
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionsControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  String _pollDuration = "1 Week";

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles = images.map((x) => File(x.path)).toList();
        _mediaType = 'image';
        _showPollCreator = false;
        _currentStep = 1; // Go to Editor
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedFiles = [File(video.path)];
        _mediaType = 'video';
        _showPollCreator = false;
        _currentStep = 2; // Skip editor for video, go to preview
      });
    }
  }

  void _togglePoll() {
    setState(() {
      _showPollCreator = !_showPollCreator;
      if (_showPollCreator) {
        _selectedFiles = [];
        _mediaType = null;
      }
    });
  }

  void _addPollOption() {
    if (_pollOptionsControllers.length < 4) {
      setState(() {
        _pollOptionsControllers.add(TextEditingController());
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty && !_showPollCreator) return;

    if (_showPollCreator && _pollQuestionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a poll question")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      List<String> mediaUrls = [];
      String finalPostType = 'text';

      // 1. Upload Media
      if (_selectedFiles.isNotEmpty) {
        final uploaded = await FeedApi.uploadMedia(_selectedFiles);
        mediaUrls = uploaded.map((u) => u["url"] as String).toList();
        finalPostType = _mediaType == 'video' ? 'video' : 'image';
      }

      // 2. Prepare Poll Data
      Map<String, dynamic>? pollData;
      if (_showPollCreator) {
        finalPostType = 'poll';
        pollData = {
          "options": _pollOptionsControllers
              .map((c) => c.text.trim())
              .where((t) => t.isNotEmpty)
              .toList(),
          "duration": _pollDuration,
        };
      }

      // 3. Create Post
      await FeedApi.createPost(
        content: _showPollCreator
            ? _pollQuestionController.text.trim()
            : content,
        mediaUrls: mediaUrls,
        postType: finalPostType,
        pollData: pollData,
        category: 'Professional', // Default as per frontend
        visibility: 'public',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post created successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("❌ Create Post Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to post: $e")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // =========================
  // 🖥 UI BUILDERS
  // =========================

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 1 && _mediaType == 'image') {
      return _buildImageEditor();
    } else if (_currentStep == 2) {
      return _buildPreview();
    } else {
      return _buildCompose();
    }
  }

  // 1. COMPOSE STEP
  Widget _buildCompose() {
    final theme = Theme.of(context);
    // ... use previous UI layout but simplified
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Post"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isPosting ? null : _submitPost,
              child: const Text(
                "Post",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "What do you want to talk about?",
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_showPollCreator) _buildPollCreator(theme),
                ],
              ),
            ),
          ),
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add to your post",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                context,
                icon: Icons.image_outlined,
                label: "Photo",
                color: Colors.blue,
                onTap: _pickImages,
              ),
              _actionButton(
                context,
                icon: Icons.videocam_outlined,
                label: "Video",
                color: Colors.pink,
                onTap: _pickVideo,
              ),
              _actionButton(
                context,
                icon: Icons.poll_outlined,
                label: "Poll",
                color: Colors.orange,
                onTap: _togglePoll,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. IMAGE EDITOR STEP
  Widget _buildImageEditor() {
    final theme = Theme.of(context);
    // currentImage was unused

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for editor
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() {
            _selectedFiles = []; // Check if user wants to cancel
            _currentStep = 0;
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _currentStep = 2), // Go to Preview
            child: const Text(
              "Next",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // MAIN IMAGE AREA
          Expanded(
            child: PageView.builder(
              itemCount: _selectedFiles.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (context, index) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: _ratios[_aspectRatioIndex],
                    child: Transform.scale(
                      scale: _zoomLevel,
                      child: Image.file(
                        _selectedFiles[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // CONTROLS
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF202124),
            child: Column(
              children: [
                // Zoom Slider
                Row(
                  children: [
                    const Text("Zoom", style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Slider(
                        value: _zoomLevel,
                        min: 1.0,
                        max: 3.0,
                        activeColor: theme.primaryColor,
                        onChanged: (v) => setState(() => _zoomLevel = v),
                      ),
                    ),
                  ],
                ),
                // Ratio Toggle
                Row(
                  children: [
                    const Text("Ratio", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    ToggleButtons(
                      isSelected: List.generate(
                        3,
                        (i) => i == _aspectRatioIndex,
                      ),
                      onPressed: (i) => setState(() => _aspectRatioIndex = i),
                      fillColor: theme.primaryColor,
                      selectedColor: Colors.white,
                      color: Colors.grey,
                      borderColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      children: _ratioLabels
                          .map(
                            (l) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(l),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                // Caption
                const SizedBox(height: 12),
                TextField(
                  controller: _textController, // Shared controller
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Write a caption...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFF303134),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. PREVIEW STEP
  Widget _buildPreview() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Preview Post"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentStep = 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isPosting ? null : _submitPost,
              style: TextButton.styleFrom(backgroundColor: theme.primaryColor),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Post", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage("lib/images/profile.png"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Just now",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_selectedFiles.isNotEmpty)
              SizedBox(
                height: 400,
                child: PageView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (ctx, i) =>
                      Image.file(_selectedFiles[i], fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _textController.text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Keep helper methods like _actionButton and _buildPollCreator from previous implementation)
  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPollCreator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Create a Poll",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _togglePoll,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pollQuestionController,
            decoration: const InputDecoration(
              hintText: "Ask a question...",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._pollOptionsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Option ${index + 1}",
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            );
          }),
          if (_pollOptionsControllers.length < 4)
            TextButton.icon(
              onPressed: _addPollOption,
              icon: const Icon(Icons.add),
              label: const Text("Add Option"),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _pollDuration,
            decoration: const InputDecoration(
              labelText: "Poll Duration",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: [
              "1 Day",
              "3 Days",
              "1 Week",
              "2 Weeks",
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _pollDuration = v!),
          ),
        ],
      ),
    );
  }
}
