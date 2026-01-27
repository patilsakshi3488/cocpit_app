import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/onboarding_service.dart';
import '../bottom_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _onboardingService = OnboardingService();

  final _nameCtrl = TextEditingController();
  File? _avatarImage;

  bool _isLoading = false;
  bool _isCheckingName = false;
  bool _isNameAvailable = false;
  String? _nameError;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Reset state checking
    setState(() {
      _isNameAvailable = false;
      _nameError = null;
    });

    if (value.length < 3) {
      // Don't error immediately, let them type
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkNameAvailability(value);
    });
  }

  Future<void> _checkNameAvailability(String name) async {
    // Local validation
    final validChars = RegExp(r'^[a-z0-9_]+$');
    if (!validChars.hasMatch(name)) {
      setState(
        () => _nameError = "Lowercase letters, numbers, and underscores only.",
      );
      return;
    }

    setState(() => _isCheckingName = true);

    final available = await _onboardingService.checkAccountName(name);

    if (mounted) {
      setState(() {
        _isCheckingName = false;
        _isNameAvailable = available;
        if (!available) {
          _nameError = "Username is already taken.";
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _avatarImage = File(picked.path));
    }
  }

  Future<void> _completeSetup() async {
    if (_avatarImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture is required")),
      );
      return;
    }

    if (!_isNameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose a valid available username"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _onboardingService.completeOnboarding(
      accountName: _nameCtrl.text.trim(),
      avatarImage: _avatarImage!,
    );

    if (mounted) setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const AppBottomNavigation(currentIndex: 0),
        ), // Home
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to complete setup. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to Cocpit!",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's set up your profile to get started.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Avatar Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainer,
                          image: _avatarImage != null
                              ? DecorationImage(
                                  image: FileImage(_avatarImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                            color: _avatarImage == null
                                ? theme.dividerColor
                                : theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: _avatarImage == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: theme.iconTheme.color,
                              )
                            : null,
                      ),
                      if (_avatarImage != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Upload Profile Picture",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Username Section
              Text("Create a username", style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                onChanged: _onNameChanged,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "username",
                  prefixText: "@",
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer.withValues(
                    alpha: 0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _isCheckingName
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (_isNameAvailable
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : (_nameError != null
                                  ? const Icon(Icons.error, color: Colors.red)
                                  : null)),
                ),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _nameError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  "3-20 characters, lowercase letters, numbers & underscores.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 60),

              // Complete Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || _avatarImage == null || !_isNameAvailable)
                      ? null
                      : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: theme.colorScheme.surfaceContainer,
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Complete Setup",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
