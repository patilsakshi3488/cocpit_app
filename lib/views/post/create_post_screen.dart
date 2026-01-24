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
  // 1: Edit Image (Zoom, Ratio)
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

  // Category Data
  String _category = 'Professional';
  final List<String> _categories = ['Personal', 'Professional', 'Achievement'];

  bool _isArticle = false;
  final TextEditingController _titleController = TextEditingController();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images.map((x) => File(x.path)));
        _mediaType = 'image';
        _showPollCreator = false;
        _isArticle = false;
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
        _isArticle = false;
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
        _isArticle = false;
      }
    });
  }

  void _toggleArticle() {
    setState(() {
      _isArticle = !_isArticle;
      if (_isArticle) {
        _showPollCreator = false;
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
    if (content.isEmpty &&
        _selectedFiles.isEmpty &&
        !_showPollCreator &&
        !_isArticle) {
      return;
    }

    if (_showPollCreator && _pollQuestionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a poll question")),
      );
      return;
    }

    if (_isArticle && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an article title")),
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
      } else if (_isArticle) {
        finalPostType = 'article';
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
        title: _isArticle ? _titleController.text.trim() : '',
        category: _category,
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

  // Helper for Category Selector
  Widget _buildCategorySelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          bool isSelected = _category == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _category = cat);
              },
              backgroundColor: Colors.transparent,
              selectedColor: const Color(
                0xFF6B7AFE,
              ), // Specific blue from screenshot
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade800,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 1. COMPOSE STEP
  Widget _buildCompose() {
    final theme = Theme.of(context);
    bool isSpecialMode = _isArticle || _showPollCreator;

    return Scaffold(
      backgroundColor: const Color(
        0xFF1E1F22,
      ), // Deep dark background to match screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create a post",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info & Categories (Common)
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage("lib/images/profile.jpg"),
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "You",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Post to Anyone",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCategorySelector(theme),
                  const SizedBox(height: 24),

                  // Dynamic Body
                  if (_isArticle)
                    _buildArticleBody(theme)
                  else if (_showPollCreator)
                    _buildPollBody(theme)
                  else
                    _buildDefaultBody(theme),
                ],
              ),
            ),
          ),

          // Dynamic Footer
          if (isSpecialMode)
            _buildSpecialFooter(theme)
          else
            _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildDefaultBody(ThemeData theme) {
    return TextField(
      controller: _textController,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: "What do you want to talk about?",
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
    );
  }

  Widget _buildArticleBody(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Image Placeholder
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2D31),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              style: BorderStyle.none,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                "Add a cover image or video to your article.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7AFE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Upload from computer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Title
        TextField(
          controller: _titleController,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: "Start article title here",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 16),

        // Rich Text Toolbar Mock
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF2B2D31),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Icon(Icons.format_bold, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.format_italic, color: Colors.grey),
              SizedBox(width: 16),
              Text(
                "H2",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 16),
              Text(
                "H3",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.format_list_bulleted, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.format_list_numbered, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.link, color: Colors.grey),
            ],
          ),
        ),
        // Content Area
        Container(
          height: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2D31).withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: TextField(
            controller: _textController,
            maxLines: null,
            decoration: const InputDecoration(border: InputBorder.none),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPollBody(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Question",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pollQuestionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g., What is your biggest challenge?",
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF2B2D31),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          "Options",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._pollOptionsControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Option ${index + 1}",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2B2D31),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );
        }),

        if (_pollOptionsControllers.length < 4)
          GestureDetector(
            onTap: _addPollOption,
            child: const Row(
              children: [
                Icon(Icons.add, color: Color(0xFF6B7AFE)),
                SizedBox(width: 8),
                Text(
                  "Add Option",
                  style: TextStyle(
                    color: Color(0xFF6B7AFE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        const Text(
          "Poll Duration",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2D31),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _pollDuration,
              dropdownColor: const Color(0xFF2B2D31),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: const TextStyle(color: Colors.white),
              items: [
                "1 Day",
                "3 Days",
                "1 Week",
                "2 Weeks",
              ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _pollDuration = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              // Cancel: Go back to default mode
              setState(() {
                _isArticle = false;
                _showPollCreator = false;
              });
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isPosting ? null : _submitPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7AFE),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Post",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                color: Colors.green, // Updated color
                onTap: _pickVideo,
              ),
              _actionButton(
                context,
                icon: Icons.article_outlined,
                label: "Article",
                color: Colors.deepOrange, // Updated color
                onTap: _toggleArticle,
              ),
              _actionButton(
                context,
                icon: Icons.poll_outlined,
                label: "Poll",
                color: Colors.deepPurple, // Updated color
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

    // Using a dialog-like full screen approach
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F22), // Dark bg matching screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Create a post",
          style: TextStyle(color: Colors.white),
        ),
        leading: const SizedBox(), // Hide default back
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Section: Info + Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("lib/images/profile.jpg"),
                      radius: 18,
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Post to Anyone",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(theme),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // MAIN IMAGE AREA
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              clipBehavior: Clip.antiAlias,
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
          ),

          // CONTROLS & THUMBNAILS
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Zoom Slider
                Row(
                  children: [
                    const Text("Zoom", style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: const Color(0xFF6B7AFE),
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: const Color(0xFF6B7AFE),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _zoomLevel,
                          min: 1.0,
                          max: 3.0,
                          onChanged: (v) => setState(() => _zoomLevel = v),
                        ),
                      ),
                    ),
                  ],
                ),
                // Ratio
                Row(
                  children: [
                    const Text("Ratio", style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: List.generate(_ratioLabels.length, (index) {
                          bool isSelected = _aspectRatioIndex == index;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _aspectRatioIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.grey[700]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _ratioLabels[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Thumbnails
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedFiles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == _selectedFiles.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        );
                      }
                      bool isSelected = index == _currentImageIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _currentImageIndex = index),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF6B7AFE),
                                    width: 2,
                                  )
                                : null,
                            image: DecorationImage(
                              image: FileImage(_selectedFiles[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Caption Field
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write a caption...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
                const SizedBox(height: 20),

                // FOOTER ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _currentStep = 2), // Preview
                      icon: const Icon(
                        Icons.remove_red_eye_outlined,
                        color: Color(0xFF6B7AFE),
                        size: 18,
                      ),
                      label: const Text(
                        "Preview",
                        style: TextStyle(color: Color(0xFF6B7AFE)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isPosting ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7AFE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Post",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage("lib/images/profile.jpg"),
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

            // Category Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    bool isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                        selectedColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
    return Container(); // Deprecated helper, using _buildPollBody now
  }
}
