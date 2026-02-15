import 'package:flutter/material.dart';
import '../../../../models/job_model.dart';
import 'task_review_modal.dart'; // Reuse for media player if needed or keep simple

class ApplicantSubmissionCard extends StatefulWidget {
  final Job job;

  const ApplicantSubmissionCard({super.key, required this.job});

  @override
  State<ApplicantSubmissionCard> createState() => _ApplicantSubmissionCardState();
}

class _ApplicantSubmissionCardState extends State<ApplicantSubmissionCard> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isVideo = (widget.job.submissionType?.toLowerCase().contains('video') ?? false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(
                 isVideo ? Icons.videocam : Icons.mic,
                 color: Colors.blueAccent,
                 size: 20
               ),
               const SizedBox(width: 8),
               Text(
                "Your Submission",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.job.taskInstruction != null) ...[
            Text("Task Instruction:", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              widget.job.taskInstruction!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submission Player
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  child: IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.blueAccent,
                    onPressed: () {
                      setState(() {
                         _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.submissionType ?? "Submission",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.job.submissionDate != null 
                             ? "Submitted ${_formatDate(widget.job.submissionDate!)}"
                             : "Submitted just now",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.job.submissionUrl != null)
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20),
                     color: theme.iconTheme.color?.withOpacity(0.7),
                    onPressed: () {
                      // Mock download
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Downloading submission...")),
                      );
                    },
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
