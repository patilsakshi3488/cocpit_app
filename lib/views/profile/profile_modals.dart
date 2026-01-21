import 'package:flutter/material.dart';
import 'profile_models.dart';
import '../../services/profile_service.dart';

class EditIdentityModal extends StatefulWidget {
  final String initialOpenTo;
  final String initialAvailability;
  final String initialPreference;

  const EditIdentityModal({
    super.key,
    required this.initialOpenTo,
    required this.initialAvailability,
    required this.initialPreference,
  });

  @override
  State<EditIdentityModal> createState() => _EditIdentityModalState();
}

class _EditIdentityModalState extends State<EditIdentityModal> {
  late String openTo;
  late String availability;
  late String preference;

  @override
  void initState() {
    super.initState();
    openTo = widget.initialOpenTo;
    availability = widget.initialAvailability;
    preference = widget.initialPreference;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Edit Professional Identity",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.textTheme.bodySmall?.color),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection("Open to", ["Full-time", "Freelance", "Consulting", "Mentorship"], openTo, (val) => setState(() => openTo = val)),
          const SizedBox(height: 32),
          _buildSection("Availability", ["Immediate", "30 Days", "Casual Networking"], availability, (val) => setState(() => availability = val), activeColor: Colors.green),
          const SizedBox(height: 32),
          _buildSection("Work Preference", ["Remote", "Hybrid", "Onsite"], preference, (val) => setState(() => preference = val)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'openTo': openTo,
              'availability': availability,
              'preference': preference,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> options, String current, Function(String) onSelect, {Color? activeColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = activeColor ?? theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((opt) {
            bool isSelected = opt == current;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primary : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? primary : theme.dividerColor),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class UploadResumeModal extends StatelessWidget {
  const UploadResumeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                "Upload Custom Resume",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.textTheme.bodySmall?.color),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Upload a PDF or DOCX file to attach to your profile.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_outlined, color: theme.primaryColor, size: 48),
                const SizedBox(height: 16),
                Text("Click to upload", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("PDF or DOCX (Max 5MB)", style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Save", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class ExperienceModal extends StatefulWidget {
  final Experience? experience;

  const ExperienceModal({super.key, this.experience});

  @override
  State<ExperienceModal> createState() => _ExperienceModalState();
}

class _ExperienceModalState extends State<ExperienceModal> {
  final ProfileService profileService = ProfileService();
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late bool _currentlyWorking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.experience?.title ?? "");
    _companyController = TextEditingController(text: widget.experience?.company ?? "");
    _startDateController = TextEditingController(text: widget.experience?.startDate ?? "");
    _endDateController = TextEditingController(text: widget.experience?.endDate ?? "");
    _locationController = TextEditingController(text: widget.experience?.location ?? "");
    _descriptionController = TextEditingController(text: widget.experience?.description ?? "");
    _currentlyWorking = widget.experience?.currentlyWorking ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      bool success;
      if (widget.experience != null) {
        success = await profileService.updateExperience(
          id: widget.experience!.id!,
          title: _titleController.text,
          company: _companyController.text,
          location: _locationController.text,
          startDate: _startDateController.text,
          endDate: _currentlyWorking ? null : _endDateController.text,
          isCurrent: _currentlyWorking,
          description: _descriptionController.text,
        );
      } else {
        success = await profileService.addExperience(
          title: _titleController.text,
          company: _companyController.text,
          location: _locationController.text,
          startDate: _startDateController.text,
          endDate: _currentlyWorking ? null : _endDateController.text,
          currentlyWorking: _currentlyWorking,
          description: _descriptionController.text,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving experience: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.experience == null) return;
    setState(() => _isLoading = true);
    try {
      final success = await profileService.deleteExperience(widget.experience!.id!);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error deleting experience: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isEdit = widget.experience != null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Text(
                  isEdit ? "Edit Experience" : "Add Experience",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textTheme.bodySmall?.color),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel("Title"),
            _buildTextField(_titleController, "Ex: Product Manager"),
            _buildLabel("Company"),
            _buildTextField(_companyController, "Ex: Microsoft"),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Start Date"),
                      _buildDateField(_startDateController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("End Date"),
                      _buildDateField(_endDateController, enabled: !_currentlyWorking),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _currentlyWorking,
                  onChanged: (val) => setState(() => _currentlyWorking = val ?? false),
                  side: BorderSide(color: theme.dividerColor),
                  activeColor: theme.primaryColor,
                ),
                Text("I currently work here", style: theme.textTheme.bodyMedium),
              ],
            ),
            _buildLabel("Location"),
            _buildTextField(_locationController, "Ex: London, UK"),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Describe your responsibilities...", maxLines: 4),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (isEdit)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: _handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error.withOpacity(0.1),
                            foregroundColor: colorScheme.error,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodySmall,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, {bool enabled = true}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      style: theme.textTheme.bodyLarge?.copyWith(color: enabled ? null : theme.textTheme.bodySmall?.color),
      decoration: InputDecoration(
        suffixIcon: Icon(Icons.calendar_today, color: theme.textTheme.bodySmall?.color, size: 18),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      readOnly: true,
      onTap: () async {
        if (!enabled) return;
        DateTime? initial = DateTime.now();
        if (controller.text.isNotEmpty) {
          try {
            initial = DateTime.parse(controller.text);
          } catch (_) {}
        }
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          controller.text = pickedDate.toIso8601String();
        }
      },
    );
  }
}

class EducationModal extends StatefulWidget {
  final Education? education;

  const EducationModal({super.key, this.education});

  @override
  State<EducationModal> createState() => _EducationModalState();
}

class _EducationModalState extends State<EducationModal> {
  final ProfileService profileService = ProfileService();

  late TextEditingController _schoolController;
  late TextEditingController _degreeController;
  late TextEditingController _fieldController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;

  bool _currentlyStudying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _schoolController = TextEditingController(text: widget.education?.school ?? "");
    _degreeController = TextEditingController(text: widget.education?.degree ?? "");
    _fieldController = TextEditingController(text: widget.education?.fieldOfStudy ?? "");
    _startDateController = TextEditingController(text: widget.education?.startYear ?? "");
    _endDateController = TextEditingController(text: widget.education?.endYear ?? "");
    _descriptionController = TextEditingController(text: widget.education?.description ?? "");
    _currentlyStudying = widget.education?.currentlyStudying ?? false;
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      bool success;
      if (widget.education != null) {
        success = await profileService.updateEducation(
          id: widget.education!.id!,
          school: _schoolController.text,
          degree: _degreeController.text,
          fieldOfStudy: _fieldController.text,
          startDate: _startDateController.text,
          endDate: _currentlyStudying ? null : _endDateController.text,
          description: _descriptionController.text,
        );
      } else {
        success = await profileService.addEducation(
          school: _schoolController.text,
          degree: _degreeController.text,
          fieldOfStudy: _fieldController.text,
          startDate: _startDateController.text,
          endDate: _currentlyStudying ? null : _endDateController.text,
          description: _descriptionController.text,
        );
      }
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Education save error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.education == null) return;
    setState(() => _isLoading = true);
    try {
      final success = await profileService.deleteEducation(widget.education!.id!);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Education delete error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.education != null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Text(
                  isEdit ? "Edit Education" : "Add Education",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLabel("School"),
            _buildTextField(_schoolController, "Ex: Stanford University"),
            _buildLabel("Degree"),
            _buildTextField(_degreeController, "Ex: B.Tech"),
            _buildLabel("Field of Study"),
            _buildTextField(_fieldController, "Ex: Computer Science"),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Start Date"),
                      _buildDateField(_startDateController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("End Date"),
                      _buildDateField(_endDateController, enabled: !_currentlyStudying),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _currentlyStudying,
                  onChanged: (v) {
                    setState(() {
                      _currentlyStudying = v ?? false;
                      if (_currentlyStudying) _endDateController.clear();
                    });
                  },
                ),
                const Text("I'm still studying"),
              ],
            ),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Description", maxLines: 4),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (isEdit)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error.withOpacity(0.1),
                          foregroundColor: colorScheme.error,
                        ),
                        child: const Text("Delete"),
                      ),
                    ),
                  if (isEdit) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, {bool enabled = true}) {
    return TextField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today)),
      onTap: () async {
        if (!enabled) return;
        DateTime? initial = DateTime.now();
        if (controller.text.isNotEmpty) {
          try {
            initial = DateTime.parse(controller.text);
          } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = picked.toIso8601String();
        }
      },
    );
  }
}

class SkillsModal extends StatefulWidget {
  // final List<dynamic> initialSkills;
  final List<Skill> initialSkills;

  const SkillsModal({super.key, required this.initialSkills});

  @override
  State<SkillsModal> createState() => _SkillsModalState();
}

class _SkillsModalState extends State<SkillsModal> {
  final ProfileService profileService = ProfileService();
  final TextEditingController _skillController = TextEditingController();

  List<Skill> _workingSkills = [];
  List<Skill> _originalSkills = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // for (final item in widget.initialSkills) {
    //   final skill = Skill.fromJson(item);
    //   _originalSkills.add(skill);
    //   _workingSkills.add(skill);
    // }

   // changes by jules
    // Copy the list to avoid modifying the original list reference
    // Create new instances or just reference since Skill is immutable-ish (only final fields)
    // Actually, we want a shallow copy of the list containing the same Skill objects
    // But since we compare IDs, it's fine.
    _originalSkills = List.from(widget.initialSkills);
    _workingSkills = List.from(widget.initialSkills);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addPendingSkillIfAny() {
    final text = _skillController.text.trim();
    if (text.isNotEmpty) {
      _addLocalSkill();
    }
  }

  void _addLocalSkill() {
    final text = _skillController.text.trim();
    if (text.isEmpty) return;
    if (_workingSkills.any((s) => s.name.toLowerCase() == text.toLowerCase())) return;

    setState(() {
      _workingSkills.add(Skill(id: 'temp_${DateTime.now().millisecondsSinceEpoch}', name: text));
      _skillController.clear();
    });
  }

  void _removeLocalSkill(Skill skill) {
    setState(() {
      _workingSkills.removeWhere((s) => s.id == skill.id);
    });
  }

  Future<void> _saveChanges() async {
    _addPendingSkillIfAny();

    setState(() => _isSaving = true);

    try {
      // Added skills (temporary IDs)
      final addedNames = _workingSkills
          .where((s) => s.id.startsWith('temp_'))
          .map((s) => s.name)
          .toList();

      // Removed skills
      final removed = _originalSkills
          .where((orig) => !_workingSkills.any((w) => w.id == orig.id))
          .toList();

      // Delete removed skills
      for (final s in removed) {
        await profileService.deleteSkill(s.id);
      }

      // Add new skills (BATCH)
      if (addedNames.isNotEmpty) {
        await profileService.addSkills(addedNames);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Save skills error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text("Manage Skills", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillController,
                  decoration: InputDecoration(
                    hintText: "Add a new skill...",
                    filled: true,
                    fillColor: scheme.surfaceContainer.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),

                  onSubmitted: (_) => _addLocalSkill(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _addLocalSkill, child: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _workingSkills.map((skill) => _chip(skill, () => _removeLocalSkill(skill), theme, scheme)).toList(),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _chip(Skill skill, VoidCallback onDelete, ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill.name, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
