import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signin_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final authService = AuthService();

  String selectedRole = 'Select your role';

  final roles = [
    'Select your role',
    'fresher',
    'employer',
    'freelancer',
    'student',
    'admin',
  ];

  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  String _mapAccountType(String role) {
    if (role.toLowerCase() == 'employer') {
      return 'Employer';
    }
    return 'User';
  }

  Future<void> _createAccount() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      _showMsg("All fields are required");
      return;
    }

    if (selectedRole == 'Select your role') {
      _showMsg("Please select your role");
      return;
    }

    if (!isEmailVerified) {
      _showMsg("Please verify your email address first");
      return;
    }

    try {
      setState(() => isLoading = true);

      // 1. Register
      final success = await authService.register(
        fullName: nameCtrl.text.trim(),
        email: emailCtrl.text.trim().toLowerCase(),
        password: passCtrl.text.trim(),
        accountType: _mapAccountType(selectedRole),
      );

      if (success) {
        // 2. Auto Login to get token for Onboarding
        final loginSuccess = await authService.login(
          email: emailCtrl.text.trim().toLowerCase(),
          password: passCtrl.text.trim(),
        );

        if (mounted) setState(() => isLoading = false);

        if (loginSuccess != null) {
          // 3. Navigate to Onboarding
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          _showMsg("Account created, but login failed. Please sign in.");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            );
          }
        }
        return;
      }

      if (mounted) setState(() => isLoading = false);
      _showMsg("Signup failed");

      _showMsg("Signup failed");
    } catch (e) {
      debugPrint("Signup error: $e");
      if (mounted) setState(() => isLoading = false);
      _showMsg("Server error. Please try again later.");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogoSection(theme),
              const SizedBox(height: 48),
              Text(
                "Create your account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join Cocpit to connect and grow with professionals.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              _fieldLabel(theme, "Full Name"),
              _customTextField(
                theme: theme,
                controller: nameCtrl,
                hint: "John Doe",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),

              _fieldLabel(theme, "Email"),
              Row(
                children: [
                  Expanded(
                    child: _customTextField(
                      theme: theme,
                      controller: emailCtrl,
                      hint: "you@example.com",
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _verifyButton(theme),
                ],
              ),
              const SizedBox(height: 24),

              _fieldLabel(theme, "Password"),
              _customTextField(
                theme: theme,
                controller: passCtrl,
                hint: "Create a strong password",
                icon: Icons.lock_outline,
                obscureText: !isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.textTheme.bodySmall?.color,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),

              _fieldLabel(theme, "I am a"),
              _roleDropdown(theme),

              const SizedBox(height: 48),
              _buildSubmitButton(theme),

              const SizedBox(height: 32),
              _buildOrDivider(theme),

              const SizedBox(height: 24),
              _buildSocialButtons(theme),

              const SizedBox(height: 32),
              _buildLoginFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.business_center_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          "Cocpit",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  Widget _customTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            size: 20,
          ),
          border: InputBorder.none,
          isDense: true,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  bool isEmailVerified = false;

  void _onVerifyPressed() {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMsg("Please enter a valid email address");
      return;
    }
    _showVerifyDialog();
  }

  void _showVerifyDialog() {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter any 6-digit OTP to verify your email."),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "123456",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (otpCtrl.text.length == 6) {
                Navigator.pop(ctx);
                setState(() => isEmailVerified = true);
                _showMsg("Email verified successfully!");
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Please enter 6 digits")),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  Widget _verifyButton(ThemeData theme) {
    if (isEmailVerified) {
      return Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Icon(Icons.check_circle, color: Colors.green),
      );
    }

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _onVerifyPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.textTheme.bodyLarge?.color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: const Text(
          "Verify",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _roleDropdown(ThemeData theme) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.textTheme.bodySmall?.color,
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: selectedRole == 'Select your role'
                ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                : theme.textTheme.bodyLarge?.color,
          ),
          items: roles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => selectedRole = v!),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OR",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }

  Widget _buildSocialButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _socialBtn(theme, "GitHub", Icons.code_rounded)),
        const SizedBox(width: 16),
        Expanded(
          child: _socialBtn(theme, "Google", Icons.g_mobiledata_rounded),
        ),
      ],
    );
  }

  Widget _socialBtn(ThemeData theme, String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 24, color: theme.iconTheme.color),
      label: Text(label, style: theme.textTheme.bodyLarge),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: theme.dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoginFooter(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Already have an account? ", style: theme.textTheme.bodyMedium),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            child: Text(
              "Sign in",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
