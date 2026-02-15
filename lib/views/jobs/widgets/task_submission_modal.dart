import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../task_recording_screen.dart';

class TaskSubmissionModal extends StatefulWidget {
  final String taskType;
  final String instruction;
  final Function(String, String) onSubmit; // (type, data)

  const TaskSubmissionModal({
    super.key,
    required this.taskType,
    required this.instruction,
    required this.onSubmit,
  });

  @override
  State<TaskSubmissionModal> createState() => _TaskSubmissionModalState();
}

class _TaskSubmissionModalState extends State<TaskSubmissionModal> {
  String? _selectedMode; // 'record' or 'file'
  String? _attachmentPath; // Display name
  String? _realAttachmentPath; // Actual path for upload

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isVoice = widget.taskType.toLowerCase().contains('voice');

    return Dialog(
      backgroundColor: const Color(0xFF1E2024), // Dark background matching design
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "Submit ${isVoice ? 'Voice' : 'Video'} Response",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            
              // Instruction Box
              if (widget.instruction.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instruction",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.instruction,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
            
              const SizedBox(height: 24),
            
              if (_attachmentPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedMode == 'record' ? (isVoice ? Icons.mic : Icons.videocam) : Icons.insert_drive_file,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _attachmentPath!,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                        onPressed: () {
                          setState(() {
                            _attachmentPath = null;
                            _realAttachmentPath = null;
                            _selectedMode = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        label: "Record Now",
                        icon: isVoice ? Icons.mic : Icons.videocam,
                        color: Colors.redAccent,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TaskRecordingScreen(
                              taskType: widget.taskType,
                              instruction: widget.instruction,
                              isModalMode: true, // New flag to return result
                            )),
                          );
                          
                          if (result != null && result is String) {
                            setState(() {
                              _selectedMode = 'record';
                              _attachmentPath = "Recorded_${isVoice ? 'Audio' : 'Video'}.mp4";
                              _realAttachmentPath = result; // Assuming result is the path
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionCard(
                        label: "Upload File",
                        icon: Icons.upload_file,
                        color: Colors.blueAccent,
                        onTap: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                            );

                            if (result != null && result.files.single.path != null) {
                              setState(() {
                                _selectedMode = 'file';
                                _attachmentPath = result.files.single.name; 
                                _realAttachmentPath = result.files.single.path;
                              });
                            }
                          } catch (e) {
                            debugPrint("Error picking file: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error picking file: $e")),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            
              const SizedBox(height: 24),
            
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _realAttachmentPath == null ? null : () {
                      widget.onSubmit(_selectedMode!, _realAttachmentPath!);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withOpacity(0.1),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Submit Response"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: color.withOpacity(0.2),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: color, size: 24),
             ),
             const SizedBox(height: 12),
             Text(
               label,
               style: const TextStyle(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
                 fontSize: 14,
               ),
             ),
          ],
        ),
      ),
    );
  }
}


