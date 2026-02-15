import 'dart:convert';
import 'widgets/applicant_details_modal.dart';
import 'widgets/shortlist_confirmation_modal.dart';
import 'widgets/task_review_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/applicant_model.dart';
import '../../services/job_provider.dart';
import '../../services/secure_storage.dart';
import '../profile/profile_screen.dart';
import '../profile/public_profile_screen.dart';

class JobApplicantsView extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  // Callback to go back to dashboard if needed, though Tabs might handle it
  // final VoidCallback? onBack; 

  const JobApplicantsView({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsView> createState() => _JobApplicantsViewState();
}


class _JobApplicantsViewState extends State<JobApplicantsView> {
  List<Applicant>? _applicants;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      final applicants = await Provider.of<JobProvider>(context, listen: false)
          .fetchJobApplicants(widget.jobId);
      if (mounted) {
        setState(() {
          _applicants = applicants;
          


          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateApplicantStatus(String applicantId, String newStatus, {Map<String, dynamic>? screening}) async {
    final applicant = _applicants?.firstWhere((a) => a.id == applicantId);
    if (applicant == null) return;
    
    try {
      await Provider.of<JobProvider>(context, listen: false).updateApplicationStatus(
        applicant.applicationId, 
        newStatus, 
        screening: screening
      );
      
      // Refresh list to show updated status
      await _loadApplicants();

      if (mounted) {
        String msg = "Status updated to $newStatus";
        if (screening != null && screening['required'] == true) {
          msg += " (Task Assigned)";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We return a DefaultTabController directly to be embedded
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   "Applicants",
                   style: theme.textTheme.headlineMedium?.copyWith(
                     fontWeight: FontWeight.bold,
                     color: Colors.white, 
                   ),
                 ),
                 const SizedBox(height: 4),
                  if (_applicants != null)
                     Text(
                       "${_applicants!.length} applicants",
                       style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                     )
                  else
                     Text(
                       "Loading...",
                       style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                     ),
               ],
             ),
           ),
           
           // Tabs
           TabBar(
             isScrollable: true,
             indicatorColor: theme.primaryColor,
             labelColor: theme.primaryColor,
             unselectedLabelColor: Colors.grey,
             labelStyle: const TextStyle(fontWeight: FontWeight.bold),
             tabs: const [
               Tab(text: "All"),
               Tab(text: "Shortlisted"),
               Tab(text: "Approved"),
               Tab(text: "Rejected"),
             ],
           ),
           
           const SizedBox(height: 16),
           
           // Search Bar - Simplified for now
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0),
             child: TextField(
               decoration: InputDecoration(
                 hintText: "Search applicants...",
                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
                 filled: true,
                 fillColor: theme.colorScheme.surfaceContainer,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: BorderSide.none,
                 ),
                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
               ),
             ),
           ),
           
           const SizedBox(height: 16),

           Expanded(
             child: Builder(
               builder: (context) {
                 if (_isLoading) {
                   return const Center(child: CircularProgressIndicator());
                 } else if (_error != null) {
                   return Center(child: Text("Error: $_error"));
                 } else if (_applicants == null || _applicants!.isEmpty) {
                   return Center(child: Text("No applicants yet.", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)));
                 }

                 final applicants = _applicants!;
                 // Filter logic
                 return TabBarView(
                   children: [
                     _buildApplicantList(theme, applicants), // All
                     _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase().contains('shortlisted')).toList()), // Shortlisted
                     _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase() == 'approved').toList()), // Approved
                     _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase() == 'rejected').toList()), // Rejected
                   ],
                 );
               },
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildApplicantList(ThemeData theme, List<Applicant> applicants) {
    if (applicants.isEmpty) {
      return const Center(child: Text("No applicants in this category", style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadApplicants,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: applicants.length,
        separatorBuilder: (c, i) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _applicantCard(theme, applicants[index]);
        },
      ),
    );
  }

  Widget _applicantCard(ThemeData theme, Applicant applicant) {
    bool isShortlisted = applicant.status.toLowerCase().contains('shortlisted');
    bool hasSubmission = applicant.submissionUrl != null;

    Color reviewStatusColor = Colors.orange;
    if (applicant.taskReviewStatus == 'Approved') reviewStatusColor = Colors.green;
    if (applicant.taskReviewStatus == 'Rejected') reviewStatusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               CircleAvatar(
                 radius: 24,
                 backgroundColor: Colors.blueAccent,
                 backgroundImage: (applicant.avatarUrl != null && applicant.avatarUrl!.isNotEmpty)
                     ? NetworkImage(applicant.avatarUrl!)
                     : null,
                 child: (applicant.avatarUrl == null || applicant.avatarUrl!.isEmpty)
                     ? Text(applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white))
                     : null,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       applicant.name,
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                       ),
                     ),
                     if (applicant.headline.isNotEmpty)
                        Text(
                         applicant.headline,
                         style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                         maxLines: 1, 
                         overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text(applicant.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                         ],
                       ),
                   ],
                 ),
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: (isShortlisted ? Colors.purpleAccent : Colors.blue).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       applicant.status.isNotEmpty ? applicant.status : "Applied",
                       style: TextStyle(
                         color: isShortlisted ? Colors.purpleAccent : Colors.blue,
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                   if (applicant.taskReviewStatus != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: reviewStatusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          applicant.taskReviewStatus!,
                          style: TextStyle(
                            color: reviewStatusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                   ]
                 ],
               ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ApplicantDetailsModal(
                        applicant: applicant,
                        onShortlist: () {
                          Navigator.pop(context);
                          _showShortlistConfirmation(applicant);
                        },
                        onReject: () {
                          Navigator.pop(context);
                          _updateApplicantStatus(applicant.id, "Rejected");
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("View Profile", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              
              if (hasSubmission)
                   Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReviewModal(applicant),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Review Task", style: TextStyle(color: Colors.white)),
                    ),
                  )
                  else if (applicant.status == 'Task Assignment' || (applicant.submissionInstruction != null && applicant.submissionInstruction!.isNotEmpty))
                   Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         // DEBUG: Show raw JSON to troubleshoot
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Debug Info"),
                            content: SingleChildScrollView(
                              child: Text(
                                "Raw JSON:\n${jsonEncode(applicant.debugJson)}\n\nParsed URL: ${applicant.submissionUrl}",
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                        );
                      }, 
                      icon: const Icon(Icons.access_time, size: 16, color: Colors.orange),
                      label: const Text("Waiting for task (Debug)", style: TextStyle(color: Colors.orange)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.orange.withOpacity(0.5))),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
              else if (isShortlisted)
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () {
                       // Logic to view resume
                     },
                     icon: const Icon(Icons.description_outlined, size: 16),
                     label: const Text("Resume"),
                      style: OutlinedButton.styleFrom(
                       side: BorderSide(color: theme.dividerColor),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                   ),
                 )
              else 
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showShortlistConfirmation(applicant),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.green.withOpacity(0.1),
                               foregroundColor: Colors.green,
                               shadowColor: Colors.transparent,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Shortlist"),
                          ),
                      ),
                      const SizedBox(width: 8),
                       OutlinedButton(
                        onPressed: () {
                          // Logic to view resume
                        },
                         style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          minimumSize: const Size(0, 0),
                         ),
                        child: const Icon(Icons.description_outlined, size: 20),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShortlistConfirmation(Applicant applicant) {
    showDialog(
      context: context,
      builder: (context) => ShortlistConfirmationModal(
        applicantName: applicant.name,
        onConfirm: (result) {
           Navigator.pop(context);
           
           Map<String, dynamic>? screening;
           if (result['isDirect'] == false) {
             screening = {
               'required': true,
               'type': result['taskType'] ?? 'Voice Introduction',
               'question': result['instruction'] ?? 'Please introduce yourself.',
             };
           }
           
           _updateApplicantStatus(applicant.id, "Shortlisted", screening: screening);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showReviewModal(Applicant applicant) {
    String type = 'Video';
    if (applicant.submissionUrl != null) {
      final url = applicant.submissionUrl!.toLowerCase();
      if (url.endsWith('.mp3') || url.endsWith('.m4a') || url.endsWith('.wav') || url.endsWith('.aac')) {
        type = 'Audio';
      }
    }

    showDialog(
      context: context,
      builder: (context) => TaskReviewModal(
        applicantName: applicant.name,
        submissionType: type, 
        submissionUrl: applicant.submissionUrl!,
        instruction: applicant.submissionInstruction ?? "No instruction",
        submittedAt: applicant.submittedAt,
        onApprove: () {
          Navigator.pop(context);
          // Confirm shortlist status or move to next stage (e.g. Approved)
          _updateApplicantStatus(applicant.id, "Approved"); 
        },
        onReject: () {
          Navigator.pop(context);
           _updateApplicantStatus(applicant.id, "Rejected");
        },
      ),
    );
  }

  Color _getReviewStatusColor(String? status) {
     if (status == 'Approved') return Colors.green;
     if (status == 'Rejected') return Colors.red;
     return Colors.orange;
  }
}
