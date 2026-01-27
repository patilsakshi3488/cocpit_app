import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../models/job_model.dart';
import '../../services/job_provider.dart';

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
    final job = provider.allJobs.firstWhere((j) => j.id == widget.job.id, orElse: () =>
       provider.jobOffers.firstWhere((j) => j.id == widget.job.id, orElse: () =>
         provider.myApplications.firstWhere((j) => j.id == widget.job.id, orElse: () =>
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
                  if (job.hasApplied)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            "Applied - ${job.applicationStatus ?? 'Submitted'}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
              ),
            ),
            const SizedBox(height: 24),
            _section(
              theme,
              "About the Job",
              job.description,
            ),
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

  Future<void> _pickResume() async {
    fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeName = result.files.single.name;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a resume")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await Provider.of<JobProvider>(context, listen: false).applyJob(
        jobId: widget.job.id,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        coverNote: _coverNoteController.text,
        resumeFile: _resumeFile!,
      );

      if (mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Application submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed to submit: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  _field(theme, _fullNameController, "John Doe"),
                  const SizedBox(height: 16),

                  _inputLabel(theme, "Email"),
                  _field(theme, _emailController, "john@example.com"),
                  const SizedBox(height: 16),

                  _inputLabel(theme, "Phone"),
                  _field(theme, _phoneController, "+1 123 456 7890"),
                  const SizedBox(height: 16),

                  _inputLabel(theme, "Resume"),
                  GestureDetector(
                    onTap: _pickResume,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
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
                  const SizedBox(height: 16),

                  _inputLabel(theme, "Cover Note (Optional)"),
                  _field(theme, _coverNoteController, "Tell us why you're a good fit...", maxLines: 4),

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
                        ? const CircularProgressIndicator(color: Colors.white)
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

  Widget _field(ThemeData theme, TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodySmall,
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
