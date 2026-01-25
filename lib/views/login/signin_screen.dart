import 'package:flutter/material.dart';

import '../../services/validator.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../feed/home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final authService = AuthService();

  bool keepLoggedIn = false;
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final success = await authService.login(
        email: emailCtrl.text,
        password: passCtrl.text,
      );

      if (!success) {
        _showSnack("Invalid email or password");
        return;
      }

      // 🔥 VERIFY SESSION FROM BACKEND
      final me = await authService.getMe();

      if (me == null) {
        _showSnack("Session error. Please login again.");
        return;
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      print("Login error: $e"); // Debug print
      _showSnack("Server error. Try again. Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoSection(theme),
                  const SizedBox(height: 48),

                  Text(
                    "Sign in",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Welcome back! Enter your details below.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  _fieldLabel(theme, "Email address"),
                  _buildTextField(
                    theme: theme,
                    controller: emailCtrl,
                    hint: "you@example.com",
                    validator: AppValidator.validateEmail,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 24),

                  _fieldLabel(theme, "Password"),
                  _buildTextField(
                    theme: theme,
                    controller: passCtrl,
                    hint: "Enter your password",
                    obscureText: !isPasswordVisible,
                    validator: null,
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildOptionsRow(theme),

                  const SizedBox(height: 48),
                  _buildSubmitButton(theme),

                  const SizedBox(height: 32),
                  _buildSignupFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== UI HELPERS (UNCHANGED) =====

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
            Icons.business_center,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          "Cocpit",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOptionsRow(ThemeData theme) {
    return Row(
      children: [
        Checkbox(
          value: keepLoggedIn,
          onChanged: (v) => setState(() => keepLoggedIn = v!),
        ),
        const Text("Keep me logged in"),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            );
          },
          child: Text(
            "Forgot password?",
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signIn,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Sign in"),
      ),
    );
  }

  Widget _buildSignupFooter(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account? "),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: Text(
              "Sign up",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
