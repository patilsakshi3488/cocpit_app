import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class PostJobModal extends StatefulWidget {
  final ThemeData theme;
  final Job? job;
  final Function(Map<String, dynamic>) onJobPosted;
  
  const PostJobModal({
    super.key, 
    required this.theme, 
    required this.onJobPosted,
    this.job,
  });

  @override
  State<PostJobModal> createState() => _PostJobModalState();
}

class _PostJobModalState extends State<PostJobModal> {
  // Form State
  String empType = "Full-time";
  String workMode = "Remote";
  String experienceLevel = "Entry Level";
  
  // Company & Industry defaults
  String companyType = "Startup";
  String industryType = "Technology";

  late TextEditingController titleController;
  late TextEditingController locationController;
  late TextEditingController minSalaryController;
  late TextEditingController maxSalaryController;
  late TextEditingController descriptionController;
  late TextEditingController skillsController;
  
  // Company Info
  late TextEditingController companyController;
  late TextEditingController aboutCompanyController;
  
  // Settings
  bool enableEasyApply = true;
  bool activelyHiring = true;
  
  // Error Text
  String? _titleError;
  String? _locationError;
  String? _companyError;

  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    
    titleController = TextEditingController(text: j?.title);
    locationController = TextEditingController(text: j?.location);
    minSalaryController = TextEditingController(text: j != null ? j.salaryMin.toString() : '');
    maxSalaryController = TextEditingController(text: j != null ? j.salaryMax.toString() : '');
    descriptionController = TextEditingController(text: j?.description);
    skillsController = TextEditingController(); // Job model lacks skills currently
    
    companyController = TextEditingController(text: j?.companyName);
    aboutCompanyController = TextEditingController(text: j?.aboutCompany);
    
    if (j != null) {
      if (["Full-time", "Part-time", "Contract", "Freelancer", "Internship"].contains(j.jobType)) {
        empType = j.jobType;
      }
      if (["Onsite", "Hybrid", "Remote"].contains(j.workMode)) {
        workMode = j.workMode;
      }
      if (["Entry Level", "Mid Level", "Senior"].contains(j.experienceLevel)) {
        experienceLevel = j.experienceLevel;
      }
      if (["Startup", "MNC", "Product-based", "Service-based"].contains(j.companyType)) {
        companyType = j.companyType;
      }
      if (["Technology", "Healthcare", "Finance", "Education", "Other"].contains(j.industry)) {
        industryType = j.industry;
      }
      
      enableEasyApply = j.easyApply;
      activelyHiring = j.activelyHiring;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job == null ? "Post a Job" : "Edit Job",
                    style: widget.theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.job == null 
                        ? "Create a new job listing to find the best talent."
                        : "Update the job details below.",
                    style: widget.theme.textTheme.bodySmall,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: widget.theme.textTheme.bodySmall?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: widget.theme.dividerColor),
          const SizedBox(height: 12),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Job Details"),
                  
                  // Row 1: Job Title | Employment Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Job Title *"),
                            _textField(
                              titleController,
                              "e.g. Senior Frontend Engineer",
                              errorText: _titleError,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Employment Type *"),
                            _dropdown(
                              empType,
                              [
                                "Full-time",
                                "Part-time",
                                "Contract",
                                "Freelancer",
                                "Internship",
                              ],
                              (v) => setState(() => empType = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Row 2: Location | Work Mode
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Location *"),
                            _textField(
                              locationController,
                              "e.g. San Francisco, CA",
                              errorText: _locationError,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Work Mode *"),
                            _dropdown(
                              workMode,
                              ["Onsite", "Hybrid", "Remote"],
                              (v) => setState(() => workMode = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Row 3: Min Salary | Max Salary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Min Salary (Annual)"),
                            _textField(
                              minSalaryController,
                              "e.g. 100000",
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Max Salary (Annual)"),
                            _textField(
                              maxSalaryController,
                              "e.g. 150000",
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Experience Level
                  _inputLabel("Experience Level"),
                  _dropdown(
                    experienceLevel,
                    ["Entry Level", "Mid Level", "Senior"],
                    (v) => setState(() => experienceLevel = v!),
                  ),

                  // Description
                  _inputLabel("Description"),
                  _textField(
                    descriptionController,
                    "Describe the role, responsibilities, and requirements...",
                    maxLines: 4,
                  ),

                  // Skills
                  _inputLabel("Skills (comma separated)"),
                  _textField(
                    skillsController,
                    "e.g. React, TypeScript, Tailwind CSS",
                  ),

                  const SizedBox(height: 32),
                  _sectionHeader("Company Information"),
                  
                  _inputLabel("Company Name *"),
                  _textField(
                    companyController,
                    "e.g. Google",
                    errorText: _companyError,
                  ),

                  // Company type & Industry row? Or stacking? 
                  // Screenshot cuts off, but typically stacking is fine or row.
                  // Let's do Row for compactness
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Company Type"),
                             _shortDropdown(
                              companyType,
                              ["Startup", "MNC", "Product-based", "Service-based"],
                              (v) => setState(() => companyType = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputLabel("Industry"),
                            _shortDropdown(
                              industryType,
                              ["Technology", "Healthcare", "Finance", "Education", "Other"],
                              (v) => setState(() => industryType = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  _inputLabel("About Company"),
                  _textField(
                    aboutCompanyController,
                    "Brief description about the company...",
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: widget.theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: BorderSide(color: widget.theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "Cancel",
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isPosting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting 
                    ? SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: widget.theme.colorScheme.onPrimary)
                      )
                    : Text(
                        widget.job == null ? "Post Job" : "Update Job",
                        style: TextStyle(
                          color: widget.theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Text(
        title,
        style: widget.theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: widget.theme.textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        label,
        style: widget.theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: widget.theme.textTheme.bodyMedium?.color, // slightly darker than small
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: widget.theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: widget.theme.textTheme.bodySmall,
        filled: true,
        fillColor: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.primaryColor),
        ),
        contentPadding: const EdgeInsets.all(16),
        errorText: errorText,
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          dropdownColor: widget.theme.scaffoldBackgroundColor,
          style: widget.theme.textTheme.bodyMedium,
          icon: Icon(Icons.keyboard_arrow_down, color: widget.theme.iconTheme.color),
        ),
      ),
    );
  }
  
  Widget _shortDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    // Same as _dropdown but intended for smaller width columns
    return _dropdown(value, items, onChanged);
  }

  void _submit() async {
    setState(() {
      _titleError = null;
      _locationError = null;
      _companyError = null;
    });

    final title = titleController.text.trim();
    final location = locationController.text.trim();
    final companyName = companyController.text.trim();

    bool isValid = true;
    if (title.isEmpty) {
      setState(() => _titleError = "Required");
      isValid = false;
    }
    if (location.isEmpty) {
      setState(() => _locationError = "Required");
      isValid = false;
    }
    if (companyName.isEmpty) {
      setState(() => _companyError = "Required");
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isPosting = true);

    final jobData = {
      'title': title,
      'company_name': companyName,
      'location': location,
      'description': descriptionController.text.trim(),
      'minSalary': int.tryParse(minSalaryController.text.trim()) ?? 0,
      'maxSalary': int.tryParse(maxSalaryController.text.trim()) ?? 0,
      'job_type': empType,
      'work_mode': workMode,
      'company_type': companyType,
      'experience_level': experienceLevel,
      'about_company': aboutCompanyController.text.trim(),
      'industry': industryType,
      'skills': skillsController.text.isNotEmpty 
          ? skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
          : [],
      'easy_apply': enableEasyApply,
      'actively_hiring': activelyHiring,
    };

    await widget.onJobPosted(jobData);
    
    if (mounted) {
      setState(() => _isPosting = false);
    }
  }
}
