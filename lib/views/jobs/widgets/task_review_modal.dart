import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TaskReviewModal extends StatefulWidget {
  final String applicantName;
  final String submissionType; // 'Voice', 'Video', 'Audio'
  final String submissionUrl;
  final String instruction;
  final DateTime? submittedAt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const TaskReviewModal({
    super.key,
    required this.applicantName,
    required this.submissionType,
    required this.submissionUrl,
    required this.instruction,
    this.submittedAt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<TaskReviewModal> createState() => _TaskReviewModalState();
}

class _TaskReviewModalState extends State<TaskReviewModal> {
  // Video
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  // Audio
  final  _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  bool _isError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (_isVideo) {
        if (widget.submissionUrl.startsWith('http')) {
          _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.submissionUrl));
        } else {
          _videoPlayerController = VideoPlayerController.file(File(widget.submissionUrl));
        }

        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
      } else {
         // Audio Setup
         _audioPlayer.onPlayerStateChanged.listen((state) {
            if (mounted) {
              setState(() => _isPlayingAudio = state == PlayerState.playing);
            }
         });
         _audioPlayer.onDurationChanged.listen((d) {
            if (mounted) setState(() => _audioDuration = d);
         });
         _audioPlayer.onPositionChanged.listen((p) {
            if (mounted) setState(() => _audioPosition = p);
         });
         
         if (widget.submissionUrl.startsWith('http')) {
            await _audioPlayer.setSourceUrl(widget.submissionUrl);
         } else {
            await _audioPlayer.setSourceDeviceFile(widget.submissionUrl);
         }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error initializing player: $e");
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  bool get _isVideo => widget.submissionType.toLowerCase().contains('video');

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: const Color(0xFF1E2024),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                      child: Row(
                        children: [
                           Icon(
                             _isVideo ? Icons.videocam : Icons.mic,
                             color: Colors.blueAccent,
                           ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Review Submission: ${widget.applicantName}",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instruction Box
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
                        "Question/Instruction",
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

                // Player Area
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isError 
                        ? const Center(child: Text("Failed to load media", style: TextStyle(color: Colors.red)))
                        : _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _isVideo
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Chewie(controller: _chewieController!),
                                  )
                                : _buildAudioPlayer(theme),
                  ),
                ),
                
                const SizedBox(height: 8),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       _isVideo ? "Video Response" : "Audio Response", 
                       style: const TextStyle(color: Colors.grey, fontSize: 12),
                     ),
                     if (widget.submissionUrl.isNotEmpty)
                       TextButton.icon(
                         onPressed: () async {
                           final Uri url = Uri.parse(widget.submissionUrl);
                           if (await canLaunchUrl(url)) {
                             await launchUrl(url, mode: LaunchMode.externalApplication);
                           } else {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Could not launch download URL")),
                               );
                             }
                           }
                         },
                         icon: const Icon(Icons.download, size: 16, color: Colors.blueAccent),
                         label: const Text("Download", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                         style: TextButton.styleFrom(
                           padding: EdgeInsets.zero,
                           minimumSize: const Size(0, 0),
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                         ),
                       ),
                   ],
                ),
                
                if (widget.submittedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Submitted: ${DateFormat('d/M/y, h:mm:ss a').format(widget.submittedAt!)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 32),

                // Actions
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Reject Candidate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Close"),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mic, size: 48, color: theme.primaryColor),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             IconButton(
               onPressed: () async {
                 if (_isPlayingAudio) {
                   await _audioPlayer.pause();
                 } else {
                   await _audioPlayer.resume();
                 }
               },
               icon: Icon(
                 _isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                 size: 64,
                 color: Colors.white,
               ),
             ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Text(_formatDuration(_audioPosition), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _audioPosition.inSeconds.toDouble(),
                  max: _audioDuration.inSeconds.toDouble(),
                  onChanged: (v) {
                    _audioPlayer.seek(Duration(seconds: v.toInt()));
                  },
                  activeColor: theme.primaryColor,
                  inactiveColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Text(_formatDuration(_audioDuration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
