                                                                                                                                                                                                                                                                                                                                       import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../models/job_model.dart';
import '../../services/job_provider.dart';
import '../../services/profile_service.dart';
import 'widgets/applicant_submission_card.dart';
import 'widgets/task_submission_modal.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<JobProvider>(context);
    // Use the job from the list in provider if possible to get updates, otherwise widget.job
    // Prioritize checking myApplications first to ensure we get the latest application status and task details
    final job = provider.myApplications.firstWhere((j) => j.id == widget.job.id, orElse: () =>
       provider.allJobs.firstWhere((j) => j.id == widget.job.id, orElse: () =>
         provider.jobOffers.firstWhere((j) => j.id == widget.job.id, orElse: () =>
           provider.mySavedJobs.firstWhere((j) => j.id == widget.job.id, orElse: () => widget.job)
         )
       )
    );

    bool isSaved = job.isSaved;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          job.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: theme.iconTheme.color),
            onPressed: () {
              // Share logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                       color: theme.primaryColor.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                    ),
                    child: Text(
                      job.initials,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    job.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        color: theme.textTheme.bodySmall?.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job.companyName,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.textTheme.bodySmall?.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job.location,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.textTheme.bodySmall?.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        job.postedTimeAgo,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(theme, job.jobType),
                      _tag(theme, job.workMode),
                      _tag(theme, job.salaryRange, isGreen: true),
                      if (job.activelyHiring)
                        _tag(theme, "Actively Hiring", isBlue: true),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (job.hasApplied) ...[
                    // Application Status Card
                    _applicationStatusCard(theme),
                    const SizedBox(height: 24),
                    
                     if (job.submissionUrl != null || job.submissionType != null) ...[
                        ApplicantSubmissionCard(job: job),
                        const SizedBox(height: 24),
                     ] else if ((job.taskAssigned || job.taskType != null || ['Task Assignment', 'Task Assigned'].contains(job.applicationStatus)) && job.submissionDate == null) ...[
                        _buildActionRequiredCard(theme, job),
                        const SizedBox(height: 24),
                     ],
                  ] else ...[
                    // Apply & Save Buttons
                    ElevatedButton(
                      onPressed: () => _showApplyModal(context, job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            job.easyApply ? "Easy Apply" : "Apply Now",
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                         try {
                           await provider.toggleSaveJob(job.id, job.isSaved);
                         } catch(e) {
                           if(mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(e.toString())),
                             );
                           }
                         }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: BorderSide(
                          color: isSaved
                              ? theme.colorScheme.secondary
                              : theme.dividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved
                                ? theme.colorScheme.secondary
                                : theme.iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSaved ? "Saved" : "Save Job",
                            style: TextStyle(
                              color: isSaved
                                  ? theme.colorScheme.secondary
                                  : theme.textTheme.bodyLarge?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              theme,
              "About the Job",
              job.description,
            ),
            if (job.hasApplied) ...[
              const SizedBox(height: 24),
              // Skills would be here if available in model, for now just Recruiter Insights
              _recruiterInsightsCard(theme),
            ],
            if (job.aboutCompany.isNotEmpty) ...[
              const SizedBox(height: 24),
              _section(
                theme,
                "About ${job.companyName}",
                job.aboutCompany,
              ),
            ],
             const SizedBox(height: 16),
            _companyInfoRow(theme, "Industry", job.industry),
            _companyInfoRow(theme, "Type", job.companyType),
            _companyInfoRow(theme, "Experience", job.experienceLevel),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showApplyModal(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApplyModal(job: job),
    );
  }

  Widget _tag(ThemeData theme, String text, {bool isGreen = false, bool isBlue = false}) {
    Color bg = theme.dividerColor.withValues(alpha: 0.1);
    Color txt = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    if (isGreen) {
      bg = Colors.green.withValues(alpha: 0.1);
      txt = Colors.greenAccent;
    } else if (isBlue) {
      bg = Colors.blue.withValues(alpha: 0.1);
      txt = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: txt,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
      ],
    );
  }

  Widget _companyInfoRow(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _applicationStatusCard(ThemeData theme) {
  final job = widget.job;
  
  // Calculate task active state explicitly
  bool isTaskActive = job.taskAssigned; 
  if (job.taskType != null && job.taskType!.isNotEmpty) {
    isTaskActive = true;
  }
  if (['Task Assignment', 'Task Assigned'].contains(job.applicationStatus)) {
    isTaskActive = true;
  }

  final steps = [
    {'label': 'Application Sent', 'active': true, 'time': 'Just now'},
    {'label': 'Application Viewed', 'active': job.applicationStatus != 'Applied', 'time': ''},
    {'label': 'Shortlisted', 'active': ['Shortlisted', 'Task Assignment', 'Interview'].contains(job.applicationStatus), 'time': ''},
    {'label': 'Task Assignment', 'active': isTaskActive, 'time': ''},
  ];

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
        Text(
          "Application Status",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
             int idx = entry.key;
             var step = entry.value;
             return Expanded(
               child: _statusStep(
                 theme, 
                 step['label'] as String, 
                 step['time'] as String, 
                 isActive: step['active'] as bool,
                 isCompleted: step['active'] as bool 
               ),
             );
          }).toList(),
        ),
      ],
    ),
  );
}

  Widget _statusStep(ThemeData theme, String title, String subtitle, {bool isActive = false, bool isCompleted = false}) {
    // Simplified timeline step
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.blueAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? Colors.blueAccent : (isActive ? Colors.blueAccent : theme.dividerColor),
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive || isCompleted ? Colors.blueAccent : theme.textTheme.bodySmall?.color,
            fontWeight: (isActive || isCompleted) ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildActionRequiredCard(ThemeData theme, Job job) {
    // Fallback to "Video Task" if taskType is missing but status says assigned
    final String effectiveTaskType = job.taskType ?? "Video Task"; 
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1B1B), // Dark orange/red background for alert
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                   "The recruiter has requested a $effectiveTaskType.",
                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
                 ),
                 if (job.taskInstruction != null && job.taskInstruction!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                       job.taskInstruction!,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                 ]
               ],
             ),
           ),
           ElevatedButton(
             onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => TaskSubmissionModal(
            taskType: effectiveTaskType,
            instruction: job.taskInstruction ?? "",
            onSubmit: (mode, data) async {
               // Data is file path
               final provider = Provider.of<JobProvider>(context, listen: false);
               
               print("DEBUG: Submitting task for App ID: ${job.applicationId}, File: $data");

               if (job.applicationId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: Application ID missing")),
                  );
                  return;
               }

               try {
                 await provider.submitTask(
                   applicationId: job.applicationId!,
                   file: File(data), 
                 );
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Task Submitted Successfully!")),
                   );
                   Navigator.pop(context); // Close details or refresh?
                   
                   // Refresh job details to update UI state
                   await provider.fetchJobDetails(job.id); 
                 }
               } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
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
             child: const Text("Start Recording"), // Or "View Task"
           ),
        ],
      ),
    );
  }

  Widget _recruiterInsightsCard(ThemeData theme) {
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
               Icon(Icons.bolt, color: Colors.blueAccent, size: 20),
               const SizedBox(width: 8),
               Text(
                "Recruiter Insights",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Recruiters are actively reviewing applications for this role.",
            style: theme.textTheme.bodySmall,
          ),
           const SizedBox(height: 20),
           Row(
             children: [
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: [
                       Text("Response Rate", style: theme.textTheme.bodySmall),
                       const SizedBox(height: 4),
                       Text(
                         "0%", // Mock
                         style: theme.textTheme.titleMedium?.copyWith(
                           color: Colors.orange,
                           fontWeight: FontWeight.bold
                         )
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: [
                       Text("Responds In", style: theme.textTheme.bodySmall),
                       const SizedBox(height: 4),
                       Text(
                         "2 days", // Mock
                         style: theme.textTheme.titleMedium?.copyWith(
                             fontWeight: FontWeight.bold
                         )
                       ),
                     ],
                   ),
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }
}

class _ApplyModal extends StatefulWidget {
  final Job job;
  const _ApplyModal({required this.job});

  @override
  State<_ApplyModal> createState() => _ApplyModalState();
}

class _ApplyModalState extends State<_ApplyModal> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverNoteController = TextEditingController();

  File? _resumeFile;
  String? _resumeName;
  bool _isSubmitting = false;

  bool? _useProfileResume;
  String? _profileResumeUrl;
  String? _profileResumeName;
  bool _isLoadingProfile = true;

  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _resumeError;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await ProfileService().getMyProfile();
      debugPrint("🔍 ApplyModal: Fetched Profile Data: $profile"); 

      if (profile != null) {
        if (mounted) {
           setState(() {
             // Parse user data from 'user' object
             final user = profile['user'];
             if (user != null) {
               _fullNameController.text = user['name'] ?? '';
               _emailController.text = user['email'] ?? '';
               _phoneController.text = user['mobile_number'] ?? '';
             }

             // Parse resume data from 'resume' object
             final resume = profile['resume'];
             if (resume != null && resume['url'] != null) {
                _profileResumeUrl = resume['url'];
                _profileResumeName = resume['originalName'] ?? _profileResumeUrl!.split('/').last;
                _useProfileResume = true;
                _resumeError = null; 
             } else {
               _profileResumeUrl = null;
               _useProfileResume = null; // Default to neither if profile resume missing, or could be false. Let's stick to null to force choice/validation as requested.
             }
             
             debugPrint("🔍 ApplyModal: Name set to: ${_fullNameController.text}, Resume: $_profileResumeUrl"); 
           });
        }
      } else {
        debugPrint("🔍 ApplyModal: Profile is NULL");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickResume() async {
    fp.FilePickerResult? result =
    await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx','jpeg','png','jpg'],
    );


    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeName = result.files.single.name;
        _useProfileResume = false; 
        _resumeError = null;
      });
    }
  }

  bool _validateForm() {
    setState(() {
      _fullNameError = _fullNameController.text.trim().isEmpty ? "Name is required" : null;
      _emailError = !_emailController.text.contains("@") ? "Enter a valid email" : null;
      
      if (_phoneController.text.isNotEmpty && _phoneController.text.length < 10) {
         _phoneError = "Enter a valid phone number";
      } else {
        _phoneError = null;
      }
      
      // If user manually switched to profile resume but it is invalid/missing
      if (_useProfileResume == true) {
        _resumeError = (_profileResumeUrl == null || _profileResumeUrl!.isEmpty) 
            ? "No profile resume found" 
            : null;
      } else if (_useProfileResume == false) {
         // Using file upload
        _resumeError = _resumeFile == null ? "Please upload your resume" : null;
      } else {
        // Neither selected
        _resumeError = "Please select one resume option to continue.";
      }
    });

    return _fullNameError == null && _emailError == null && _phoneError == null && _resumeError == null;
  }

  Future<void> _submitApplication() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_useProfileResume == true && _profileResumeUrl != null) {
         await Provider.of<JobProvider>(context, listen: false).applyJob(
          jobId: widget.job.id,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          coverNote: _coverNoteController.text.trim(),
          resumeUrl: _profileResumeUrl,
        );
      } else if (_useProfileResume == false) {
         await Provider.of<JobProvider>(context, listen: false).applyJob(
          jobId: widget.job.id,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          coverNote: _coverNoteController.text.trim(),
          resumeFile: _resumeFile!,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Application submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Failed to submit application";
        if (e.toString().contains("Already applied")) {
          // If already applied, update local state to hide the button immediately
          Provider.of<JobProvider>(context, listen: false).markJobAsApplied(widget.job.id);
          errorMessage = "You have already applied to this job.";
           // Also close the modal as if successful? Or just show error?
           // The user might want to see the error, but the button behind the modal will update.
        } else if (e.toString().contains("Resume is required")) {
          errorMessage = "Please attach a resume.";
        } else {
             // Try to extract backend message if possible
             final msgMatch = RegExp(r"'message':\s*'([^']+)'").firstMatch(e.toString());
             if (msgMatch != null) {
               errorMessage = msgMatch.group(1) ?? errorMessage;
             }
        }

        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(errorMessage)),
        );
        
        // If it was the "already applied" case, we might want to close the modal too
        if (e.toString().contains("Already applied") && mounted) {
           Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Apply to ${widget.job.title}",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.textTheme.bodySmall?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputLabel(theme, "Full Name"),
                  _field(theme, _fullNameController, "John Doe", _fullNameError), 
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel(theme, "Email"),
                             _field(theme, _emailController, "john@example.com", _emailError),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel(theme, "Mobile Number (Optional)"),
                             _field(theme, _phoneController, "+1 1234567890", _phoneError),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _inputLabel(theme, "Resume"),
                  
                  // Resume Selection
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Option 1: Profile Resume
                         InkWell(
                          onTap: () {
                             setState(() {
                               _useProfileResume = true;
                               _resumeError = null; // Clear error when switching
                             });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: _useProfileResume,
                                  onChanged: (val) => setState(() => _useProfileResume = val!),
                                  activeColor: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.description, color: Colors.blueAccent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Use Profile Resume",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _useProfileResume == true ? theme.textTheme.bodyMedium?.color : Colors.grey,
                                        ),
                                      ),
                                      if (_profileResumeName != null)
                                        Text(
                                          _profileResumeName!,
                                          style: theme.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      else if (_isLoadingProfile)
                                         Text("Loading...", style: theme.textTheme.bodySmall)
                                      else
                                           Text(
                                            "No resume found",
                                            style: TextStyle(
                                              color: _useProfileResume == true ? Colors.red : Colors.grey,
                                              fontSize: 12
                                            )
                                         ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                         // Option 2: Upload New
                        InkWell(
                          onTap: () => setState(() {
                            _useProfileResume = false;
                            _resumeError = null; // Clear error when switching
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: _useProfileResume,
                                  onChanged: (val) => setState(() => _useProfileResume = val!),
                                   activeColor: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Upload New Resume",
                                     style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _useProfileResume == false ? theme.textTheme.bodyMedium?.color : Colors.grey,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    if (_useProfileResume == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: GestureDetector(
                        onTap: _pickResume,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _resumeError != null ? Colors.red : theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _resumeFile != null ? Icons.check_circle : Icons.upload_outlined,
                                color: _resumeFile != null ? Colors.green : theme.textTheme.bodySmall?.color,
                                size: 40,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _resumeName ?? "Upload Resume",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (_resumeFile == null)
                                Text(
                                  "PDF, DOCX up to 5MB",
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_resumeError != null && _useProfileResume == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16),
                        child: Text(_resumeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                   if (_resumeError != null && _useProfileResume == true) // Show error for profile resume selection if invalid
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16),
                        child: Text(_resumeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                   if (_resumeError != null && _useProfileResume == null) // Show general error if neither selected
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16),
                        child: Text(_resumeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),


                  const SizedBox(height: 24),

                  _inputLabel(theme, "Cover Note (Optional)"),
                  _field(theme, _coverNoteController, "Tell us why you're a good fit...",null, 4),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                        ?  CircularProgressIndicator(color:theme.colorScheme.onPrimary,)
                        : Text(
                          "Submit Application",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field(ThemeData theme, TextEditingController controller, String hint, [String? errorText,int maxLines = 1]) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodySmall,
        errorText: errorText,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
