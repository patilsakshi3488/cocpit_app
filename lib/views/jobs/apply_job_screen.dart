import 'package:flutter/material.dart';

class ApplyJobScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const ApplyJobScreen({super.key, required this.job});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  /* ================= FORM ================= */
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController resumeCtrl = TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    resumeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colorScheme.onSurface),
        title: Text(
          'Back to Job Listings',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _jobHeader(theme),
                  const SizedBox(height: 24),
                  _jobDescription(theme),
                  const SizedBox(height: 24),
                  _applyForm(theme),
                ],
              ),
            ),
          ),
          _submitButton(theme),
        ],
      ),
    );
  }

  /* ================= JOB HEADER ================= */

  Widget _jobHeader(ThemeData theme) {
    final job = widget.job;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                job['initial'] ?? (job['company'] != null ? job['company'][0] : 'J'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'],
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(job['company'],
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _meta(theme, Icons.location_on_outlined, job['location']),
                    _meta(theme, Icons.work_outline, job['type']),
                    _meta(theme, Icons.schedule, job['time']),
                    Text(job['salary'],
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /* ================= DESCRIPTION ================= */

  Widget _jobDescription(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(theme, 'About the role'),
          _text(theme,
              'This is a placeholder for the full job description. '
                  'Once backend APIs are connected, this content will be fetched dynamically.'),
          _section(theme, 'Responsibilities'),
          _bullet(theme, 'Collaborate with cross-functional teams'),
          _bullet(theme, 'Design and implement new features'),
          _bullet(theme, 'Write clean and maintainable code'),
          _bullet(theme, 'Participate in code reviews'),
          _bullet(theme, 'Fix bugs and improve performance'),
          _section(theme, 'Qualifications'),
          _bullet(theme, 'Bachelor’s degree or equivalent experience'),
          _bullet(theme, '3+ years of relevant experience'),
          _bullet(theme, 'Strong problem-solving skills'),
        ],
      ),
    );
  }

  /* ================= APPLY FORM ================= */

  Widget _applyForm(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply for this Job',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _input(theme, 'Full Name', nameCtrl),
            _input(
              theme,
              'Email Address',
              emailCtrl,
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                return null;
              },
            ),
            _input(
              theme,
              'Phone Number',
              phoneCtrl,
              keyboard: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                if (!phoneRegex.hasMatch(v.trim())) return 'Enter a valid phone number';
                return null;
              },
            ),
            _input(theme, 'Resume Link (PDF / Drive URL)', resumeCtrl),
          ],
        ),
      ),
    );
  }

  /* ================= SUBMIT ================= */

  Widget _submitButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: isSubmitting ? null : _submitApplication,
          child: isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            'Apply for this Job',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /* ================= BACKEND READY SUBMIT ================= */

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      setState(() => isSubmitting = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );

      Navigator.pop(context);
    }catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit application: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  /* ================= UI HELPERS ================= */

  Widget _input(ThemeData theme, String hint, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, String? Function(String?)? validator}) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: theme.textTheme.bodyLarge,
        validator: validator ?? (v) => v == null || v.isEmpty ? 'This field is required' : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _section(ThemeData theme, String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(t,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  );

  Widget _text(ThemeData theme, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
  );

  Widget _bullet(ThemeData theme, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        Expanded(
            child: Text(t,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
      ],
    ),
  );
}
