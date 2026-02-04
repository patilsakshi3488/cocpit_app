import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _schoolController;
  late TextEditingController _degreeController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    // ✅ SAFE INITIALIZATION (null-proof)
    _nameController = TextEditingController(
      text: widget.initialData['name'] ?? '',
    );
    _headlineController = TextEditingController(
      text: widget.initialData['headline'] ?? '',
    );
    _jobTitleController = TextEditingController(
      text: widget.initialData['jobTitle'] ?? '',
    );
    _companyController = TextEditingController(
      text: widget.initialData['company'] ?? '',
    );
    _schoolController = TextEditingController(
      text: widget.initialData['school'] ?? '',
    );
    _degreeController = TextEditingController(
      text: widget.initialData['degree'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialData['location'] ?? '',
    );
    _aboutController = TextEditingController(
      text: widget.initialData['about'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialData['mobileNumber'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData['email'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    _degreeController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                "Edit Profile",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: Icon(
                Icons.save_outlined,
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                "Save Changes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      // ❌ FIX 1: REMOVED BottomNavigation from EditProfileScreen
      body: SingleChildScrollView(
        // ✅ FIX 3: Keyboard-safe ScrollView
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            // decoration: BoxDecoration(), // Removed outer border for cleaner look
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label("Full Name"),
                _field(_nameController, "Enter your name", required: true),

                _label("Headline"),
                _field(
                  _headlineController,
                  "Enter your professional headline",
                  required: true,
                ),

                _label("Job Title"),
                _field(_jobTitleController, "Enter your job title"),

                _label("Company Name"),
                _field(_companyController, "Enter your company name"),

                _label("Education (School)"),
                _field(_schoolController, "Enter your school"),

                _label("Degree"),
                _field(_degreeController, "Enter your degree"),

                _label("Location"),
                _field(
                  _locationController,
                  "Enter your location",
                  required: true,
                ),
                
                _label("Phone Number"),
                _field(
                  _phoneController, 
                  "Enter 10-digit mobile number",
                  validator: (value) {
                    if (value == null || value.isEmpty) return null; // Optional
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return "Mobile number must be exactly 10 digits";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone
                ),

                _label("Email Address"),
                _field(
                  _emailController, 
                  "Enter your email",
                  validator: (value) {
                    if (value == null || value.isEmpty) return null; // Optional
                     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    // Check for uppercase? (Requirement: 'mail not a upper case')
                    // We can just auto-convert on save, but can also warn here if strict.
                    return null;
                  },
                   keyboardType: TextInputType.emailAddress
                ),

                _label("About"),
                _field(_aboutController, "Tell us about yourself", maxLines: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // SAVE HANDLER
  // =========================
  void _onSave() {
    if (_formKey.currentState!.validate()) {
       Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'jobTitle': _jobTitleController.text.trim(),
        'company': _companyController.text.trim(),
        'school': _schoolController.text.trim(),
        'degree': _degreeController.text.trim(),
        'location': _locationController.text.trim(),
        'about': _aboutController.text.trim(),
        'mobileNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(), // ✅ FORCE LOWERCASE
      });
    }
  }

  // =========================
  // UI HELPERS
  // =========================
  Widget _label(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.cardColor, // Cleaner look
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Remove border for cleaner look
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder( // Red border on error
           borderRadius: BorderRadius.circular(12),
           borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      // No validation logic
    );
  }
}
