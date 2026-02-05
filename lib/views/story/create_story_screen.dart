import 'dart:io';
import 'package:cocpit_app/views/story/editor/story_editor_screen.dart';
import 'package:cocpit_app/views/story/preview/story_preview_screen.dart'; // ✅ ADDED
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late TabController _tabController;
  final TextEditingController _descriptionController = TextEditingController();

  // Text Tab State
  Color _selectedBackgroundColor = Colors.deepPurple;
  String _selectedTemplate = "Blank"; // Blank, Quote, Announcement

  final List<Color> _backgroundColors = [
    Colors.deepPurple,
    Colors.cyan,
    Colors.orangeAccent,
    Colors.blueGrey,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool video) async {
    try {
      final XFile? picked = video
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;
      final file = File(picked.path);

      if (mounted) {
        // ✅ SIMPLE PATH: Bypass Editor for direct gallery picks
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryPreviewScreen(
              storyFile: file,
              isVideo: video,
              isSimple: true, // ✅ New flag to avoid baking
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking media: $e");
    }
  }

  void _launchTextEditor() {
    List<TextLayer>? initialLayers;
    if (_selectedTemplate == "Quote") {
      initialLayers = [
        TextLayer(
          id: "quote",
          text: "\"Your Quote Here\"",
          color: Colors.white,
          align: TextAlign.center,
          position: const Offset(100, 300),
        ),
      ];
    } else if (_selectedTemplate == "Announcement") {
      initialLayers = [
        TextLayer(
          id: "announcement",
          text: "BIG NEWS",
          color: Colors.white,
          align: TextAlign.center,
          position: const Offset(100, 300),
          scale: 1.5,
        ),
      ];
    }

    _launchEditor(
      file: null,
      isVideo: false,
      initialBackgroundColor: _selectedBackgroundColor,
      initialTextLayers: initialLayers,
    );
  }

  // Simplified: Just push the editor. Editor pushes Preview. Preview uploads and popsUntil root.
  Future<void> _launchEditor({
    File? file,
    required bool isVideo,
    Color? initialBackgroundColor,
    List<TextLayer>? initialTextLayers,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryEditorScreen(
          initialFile: file,
          isVideo: isVideo,
          initialBackgroundColor: initialBackgroundColor,
          initialTextLayers: initialTextLayers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2432),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Create Story",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2D3447),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: "Media"),
                Tab(text: "Text & Type"),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMediaTab(), _buildTextTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload Image",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildUploadCard(
            label: "Upload Image",
            subLabel: "JPG or PNG (rec: 9:16)",
            icon: Icons.image_outlined,
            color: Colors.blueAccent,
            onTap: () => _pickMedia(false),
          ),

          const SizedBox(height: 24),

          const Text(
            "Upload Video",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildUploadCard(
            label: "Upload Video",
            subLabel: "MP4 or MOV (max 30s)",
            icon: Icons.videocam_outlined,
            color: Colors.purpleAccent,
            onTap: () => _pickMedia(true),
          ),

          const SizedBox(height: 24),

          const Text(
            "Description",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Add a description to your story...",
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose Background",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: _backgroundColors.map((color) {
              final isSelected = _selectedBackgroundColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedBackgroundColor = color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          const Text(
            "Start with Template",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTemplateChip("Blank"),
              const SizedBox(width: 12),
              _buildTemplateChip("Quote"),
              const SizedBox(width: 12),
              _buildTemplateChip("Announcement"),
            ],
          ),

          const SizedBox(height: 32),

          _buildDashedButton(),

          const SizedBox(height: 24),

          const Text(
            "Description",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Add a description to your story...",
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _launchTextEditor, // For now, behaves similar to opening editor. Story creation happens AFTER editor.
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Create Story"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label) {
    final isSelected = _selectedTemplate == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDashedButton() {
    return GestureDetector(
      onTap: _launchTextEditor,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.5),
            style: BorderStyle.none,
          ), // Can't do DashedBorder easily without package, simulating with effect or simple border
        ),
        // Custom painting for dashed border is verbose, sticking to solid customized or using ShapeDecoration if needed.
        // For simplicity/speed in this context, using a distinct look.
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              "Open Editor with Background",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String label,
    required String subLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
