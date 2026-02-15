
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/job_model.dart';
import '../../../services/job_provider.dart';
import '../../../services/secure_storage.dart';
import 'task_submission_modal.dart';

class ActionRequiredCard extends StatefulWidget {
  final Job job;

  const ActionRequiredCard({super.key, required this.job});

  @override
  State<ActionRequiredCard> createState() => _ActionRequiredCardState();
}

class _ActionRequiredCardState extends State<ActionRequiredCard> {
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkPersistence();
  }

  Future<void> _checkPersistence() async {
    final submittedApps = await AppSecureStorage.getSubmittedApplications();
    final submittedJobs = await AppSecureStorage.getSubmittedJobIds();
    
    if (mounted) {
      if ((widget.job.applicationId != null && submittedApps.contains(widget.job.applicationId)) ||
          submittedJobs.contains(widget.job.id)) {
        setState(() {
          _isSubmitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to "Video Task" if taskType is missing but status says assigned
    final String effectiveTaskType = widget.job.taskType ?? "Video Task"; 
    final isSubmitted = _isSubmitted || widget.job.submissionDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1B1B), // Dark orange/red background for alert
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: const BoxDecoration(
               color: Colors.orange,
               shape: BoxShape.circle 
             ),
             child: const Icon(Icons.bolt, color: Colors.white, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   "Action Required",
                   style: TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 14,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   isSubmitted 
                       ? "Task submitted. Waiting for review."
                       : "The recruiter has requested a $effectiveTaskType.",
                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
                 ),
                 if (widget.job.taskInstruction != null && !isSubmitted) ...[
                    const SizedBox(height: 4),
                    Text(
                       widget.job.taskInstruction!,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                 ]
               ],
             ),
           ),
           if (!isSubmitted)
             if (!isSubmitted)
               ElevatedButton(
                 onPressed: () {
                    final outerContext = context; // Capture context
                    showDialog(
                      context: context,
                      builder: (dialogContext) => TaskSubmissionModal(
                        taskType: effectiveTaskType,
                        instruction: widget.job.taskInstruction ?? "Please complete the task.",
                        onSubmit: (mode, data) async {
                           // Dialog closes immediately in TaskSubmissionModal, so we are back to outerContext
                           try {
                             final provider = Provider.of<JobProvider>(outerContext, listen: false);
                             if (widget.job.applicationId == null) throw Exception("Application ID missing");
                             
                             // Optimistic update locally
                             if (mounted) {
                               setState(() {
                                 _isSubmitted = true;
                               });
                             }

                             await provider.submitTask(
                               applicationId: widget.job.applicationId!,
                               file: File(data),
                             );
                             
                             // Force Save Persistence (Duplicate Safety)
                             await AppSecureStorage.saveSubmittedApplication(widget.job.applicationId!);
                             await AppSecureStorage.saveSubmittedJobId(widget.job.id);
                             
                             if (outerContext.mounted) {
                               showDialog(
                                 context: outerContext,
                                 builder: (context) => AlertDialog(
                                   title: const Text("Success"),
                                   content: const Text("File sent successfully!"),
                                   actions: [
                                     TextButton(
                                       onPressed: () => Navigator.pop(context),
                                       child: const Text("OK"),
                                     ),
                                   ],
                                 ),
                               );
                               // Refresh job details
                               provider.fetchJobDetails(widget.job.id);
                             }
                           } catch (e) {
                             debugPrint("Submission Error: $e");
                             if (mounted) {
                               // Revert state on error
                               setState(() {
                                 _isSubmitted = false;
                               });
                             }
                             if (outerContext.mounted) {
                               ScaffoldMessenger.of(outerContext).showSnackBar(
                                 SnackBar(content: Text("Submission failed: $e")),
                               );
                             }
                           }
                        },
                      ),
                    );
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                 ),
                 child: const Text("Start Recording"),
               ),
        ],
      ),
    );
  }
}
