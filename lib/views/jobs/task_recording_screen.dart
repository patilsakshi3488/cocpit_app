import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class TaskRecordingScreen extends StatefulWidget {
  final String taskType; // 'Voice Note' or 'Video Intro'
  final String instruction;
  final bool isModalMode;

  const TaskRecordingScreen({
    super.key,
    required this.taskType,
    required this.instruction,
    this.isModalMode = false,
  });

  @override
  State<TaskRecordingScreen> createState() => _TaskRecordingScreenState();
}

class _TaskRecordingScreenState extends State<TaskRecordingScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _secondsRecorded = 0;
  String? _recordedFilePath;
  
  // Timer
  Stream<int>? _timerStream;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Stop recording
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
          _timerStream = null;
        });
      } else {
        // Start recording
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final String path = '${directory.path}/$fileName';

          await _audioRecorder.start(const RecordConfig(), path: path);
          
          setState(() {
            _isRecording = true;
            _secondsRecorded = 0;
            _recordedFilePath = null;
            _timerStream = Stream.periodic(const Duration(seconds: 1), (x) => x + 1);
            _timerStream!.listen((seconds) {
               if(mounted) setState(() => _secondsRecorded = seconds);
            });
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Microphone permission is required to record audio.")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error recording: $e")),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isVoice = widget.taskType.toLowerCase().contains('voice');

    return Scaffold(
      backgroundColor: Colors.black, // Immersive feel
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
         padding: const EdgeInsets.all(24.0),
         child: Column(
           children: [
             // Task Info
             Text(
               widget.taskType,
               style: theme.textTheme.headlineSmall?.copyWith(
                 color: Colors.white,
                 fontWeight: FontWeight.bold,
               ),
             ),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 widget.instruction,
                 style: theme.textTheme.bodyMedium?.copyWith(
                   color: Colors.white70,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
             
             const Spacer(),
             
             // Visualizer / Camera placeholder
             Container(
               height: 200,
               width: double.infinity,
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.white.withOpacity(0.1)),
               ),
               child: Center(
                 child: isVoice 
                    ? Icon(Icons.graphic_eq, size: 80, color: _isRecording ? Colors.redAccent : Colors.grey)
                    : const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
               ),
             ),
             
             const SizedBox(height: 24),
             if (_isRecording || _recordedFilePath != null)
               Text(
                 _formatTime(_secondsRecorded),
                 style: const TextStyle(
                   color: Colors.redAccent, 
                   fontSize: 24, 
                   fontWeight: FontWeight.bold
                 ),
               ),
             
             const Spacer(),
             
             // Controls
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 if (!_isRecording && _recordedFilePath != null)
                   TextButton(
                     onPressed: () {
                        setState(() {
                          _secondsRecorded = 0; 
                          _recordedFilePath = null;
                        }); 
                     },
                     style: TextButton.styleFrom(foregroundColor: Colors.white),
                     child: const Text("Retake"),
                   ),
                   
                 const SizedBox(width: 24),
                 
                 GestureDetector(
                   onTap: _toggleRecording,
                   child: Container(
                     width: 80,
                     height: 80,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: _isRecording ? Colors.white : Colors.redAccent,
                       border: Border.all(color: Colors.white, width: 4),
                     ),
                     child: Icon(
                       _isRecording ? Icons.stop : (isVoice ? Icons.mic : Icons.videocam),
                       color: _isRecording ? Colors.redAccent : Colors.white,
                       size: 32,
                     ),
                   ),
                 ),
                 
                 const SizedBox(width: 24),
                 
                 if (!_isRecording && _recordedFilePath != null)
                   ElevatedButton(
                     onPressed: () {
                       if (widget.isModalMode) {
                          Navigator.pop(context, _recordedFilePath);
                       } else {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Task submitted successfully!")),
                         );
                       }
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blueAccent,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     ),
                     child: Text(widget.isModalMode ? "Use Recording" : "Submit"),
                   ),
               ],
             ),
             const SizedBox(height: 48),
           ],
         ),
      ),
    );
  }
}
