import 'package:flutter/material.dart';

class ShortlistConfirmationModal extends StatefulWidget {
  final String applicantName;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ShortlistConfirmationModal({
    super.key,
    required this.applicantName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ShortlistConfirmationModal> createState() => _ShortlistConfirmationModalState();
}

class _ShortlistConfirmationModalState extends State<ShortlistConfirmationModal> {
  int _selectedOption = 0; // 0: Direct Shortlist, 1: Add Task
  String _taskType = 'Voice Note'; // 'Voice Note' or 'Video Intro'
  final TextEditingController _instructionController = TextEditingController();

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21), // Dark surface color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      "Shortlist ${widget.applicantName}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Do you want to add a communication round?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOption(
                      theme,
                      index: 0,
                      icon: Icons.person_add_alt_1_outlined,
                      label: "Direct Shortlist",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOption(
                      theme,
                      index: 1,
                      icon: Icons.mic_none_outlined,
                      label: "Add Task",
                    ),
                  ),
                ],
              ),
              
              if (_selectedOption == 1) ...[
                const SizedBox(height: 24),
                
                // Task Type Section
                Text(
                  "Task Type",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTaskTypeOption(
                        theme,
                        type: 'Voice Note',
                        icon: Icons.mic_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaskTypeOption(
                        theme,
                        type: 'Video Intro',
                        icon: Icons.videocam_outlined,
                      ),
                    ),
                  ],
                ),
          
                const SizedBox(height: 24),
          
                // Instruction Section
                Text(
                  "Task Instruction / Question",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instructionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Tell us about your most challenging project...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5B7FFF)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
          
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                       final Map<String, dynamic> result = {
                         'isDirect': _selectedOption == 0,
                       };
                       
                       if (_selectedOption == 1) {
                         result['taskType'] = _taskType;
                         result['instruction'] = _instructionController.text;
                       }
                       
                       widget.onConfirm(result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Confirm Shortlist"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(ThemeData theme, {required int index, required IconData icon, required String label}) {
    bool isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B7FFF).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B7FFF) : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Shrink wrap
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
              color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey,
              size: 16 // Reduced size
            ),
            const SizedBox(width: 6), // Reduced spacing
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 16),
            const SizedBox(width: 6), // Reduced spacing
            Flexible( // Use Flexible to allow text to shrink/wrap
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12, // Reduced font size
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskTypeOption(ThemeData theme, {required String type, required IconData icon}) {
    bool isSelected = _taskType == type;
    return GestureDetector(
      onTap: () => setState(() => _taskType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B7FFF).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B7FFF) : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
              color: isSelected ? const Color(0xFF5B7FFF) : Colors.grey,
              size: 16
            ),
            const SizedBox(width: 6),
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
