import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventRegisterSheet extends StatefulWidget {
  final EventModel event;
  const EventRegisterSheet({super.key, required this.event});

  @override
  State<EventRegisterSheet> createState() => _EventRegisterSheetState();
}

class _EventRegisterSheetState extends State<EventRegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await EventService.registerForEvent(
        widget.event.id,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        jobTitle: _jobTitleCtrl.text.trim(),
      );

      if (success) {
         if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );
         }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration failed. Please try again.')),
            );
         }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Register for ${widget.event.title}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _field(theme, 'Name', 'Your Name', _nameCtrl),
              _field(theme, 'Email', 'Your Email', _emailCtrl, isEmail: true),
              _field(theme, 'Mobile', 'Your Mobile Number', _mobileCtrl, isPhone: true),
              _field(theme, 'Company', 'Your Company', _companyCtrl),
              _field(theme, 'Job Title', 'Your Job Title', _jobTitleCtrl),
              const SizedBox(height: 12),
              if (widget.event.isFree)
                _infoBox(theme, 'This is a free event.', null)
              else
                _infoBox(theme, 'This is a premium event.', 'Price: \$50'), // Placeholder price
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(ThemeData theme, String label, String hint, TextEditingController controller, {bool isEmail = false, bool isPhone = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              style: theme.textTheme.bodyLarge,
              keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (isEmail && !v.contains('@')) return 'Invalid Email';
                if (isPhone && v.length < 10) return 'Invalid Phone';
                return null;
              },
            ),
          ],
        ),
      );

  Widget _infoBox(ThemeData theme, String t1, String? t2) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(t1, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (t2 != null) ...[
              const SizedBox(height: 8),
              Text(t2, style: theme.textTheme.headlineMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register, // Reuse register for now
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed to Payment', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      );
}
