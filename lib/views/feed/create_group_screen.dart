import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/group_chat_service.dart';
import '../../services/social_service.dart';
import 'group_chat_screen.dart';
import '../../services/user_search_service.dart';
import 'dart:async';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final GroupChatService _groupService = GroupChatService();
  final SocialService _socialService = SocialService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  File? _avatarFile;

  List<Map<String, dynamic>> _allUsers = []; // Connections + Search Results
  List<Map<String, dynamic>> _displayUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isCreating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final connections = await _socialService.getMyConnections();
    if (mounted) {
      setState(() {
        _allUsers = connections;
        _displayUsers = connections;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _displayUsers = _allUsers;
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      try {
        final results = await UserSearchService.searchUsers(
          query: query,
          token: "",
        );
        if (mounted) {
          setState(() {
            _displayUsers = results
                .map(
                  (u) => {
                    'id': u.id,
                    'name': u.fullName,
                    'avatar': u.avatarUrl,
                    'headline': u.headline,
                  },
                )
                .toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name")),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final List<String> memberIds = _selectedUserIds.toList();
      // NOTE: Description is included in the backend model as per requirements
      final newGroup = await _groupService.createGroup(
        name,
        memberIds,
        description: desc,
      );

      if (newGroup != null && mounted) {
        final String groupId =
            newGroup['conversation_id'] ?? newGroup['id']?.toString();

        if (_avatarFile != null) {
          await _groupService.updateGroupAvatar(groupId, _avatarFile!);
        }

        // Wait for DB Sync
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          await _socialService.getConversations();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  conversation: {'conversation_id': groupId, 'is_group': true},
                ),
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to create group")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _memberSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dark modal color consistent with image
    final backgroundColor = const Color(0xFF1E2235);
    final inputColor = const Color(0xFF262B44);
    final primaryBlue = const Color(0xFF5161B3);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8), // Dim background
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            // Removed fixed maxHeight constraint to allow scrolling and prevent overflow
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24), // Spacer for centering
                    Text(
                      "Create New Group",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Group Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: inputColor,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : null,
                          child: _avatarFile == null
                              ? const Icon(
                                  Icons.group,
                                  size: 40,
                                  color: Colors.white24,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: backgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Group Name
                _buildLabel("Group Name"),
                _buildTextField(
                  controller: _nameController,
                  hint: "Enter group name",
                  inputColor: inputColor,
                ),
                const SizedBox(height: 16),

                // Description
                _buildLabel("Description (Optional)"),
                _buildTextField(
                  controller: _descController,
                  hint: "Enter description",
                  inputColor: inputColor,
                ),
                const SizedBox(height: 16),

                // Add Members Header & Search
                _buildLabel("Add Members"),
                _buildTextField(
                  controller: _memberSearchController,
                  hint: "Search users to add...",
                  inputColor: inputColor,
                  prefixIcon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),

                // Selected Chips
                if (_selectedUserIds.isNotEmpty) ...[
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedUserIds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final userId = _selectedUserIds.elementAt(index);
                        // Try to find user in currently displayed or all users
                        Map<String, dynamic> user = {'name': 'User'};
                        try {
                          user = _displayUsers.firstWhere(
                            (u) =>
                                (u['id'] ?? u['userId']).toString() == userId,
                            orElse: () => _allUsers.firstWhere(
                              (u) =>
                                  (u['id'] ?? u['userId']).toString() == userId,
                              orElse: () => {'name': 'User'},
                            ),
                          );
                        } catch (e) {
                          // Fallback already handled
                        }

                        return InputChip(
                          avatar: CircleAvatar(
                            backgroundImage: user['avatar'] != null
                                ? NetworkImage(user['avatar'])
                                : null,
                            child: user['avatar'] == null
                                ? const Icon(Icons.person, size: 12)
                                : null,
                          ),
                          label: Text(
                            user['name'] ?? 'User',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: primaryBlue.withOpacity(0.2),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                          onDeleted: () => _toggleUser(userId),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: primaryBlue.withOpacity(0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Members List / Selection Area
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: (_isLoading || _isSearching)
                        ? const Center(child: CircularProgressIndicator())
                        : _displayUsers.isEmpty
                        ? Center(
                            child: Text(
                              _memberSearchController.text.isEmpty
                                  ? "Search for users to add"
                                  : "No users found",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _displayUsers.length,
                            itemBuilder: (context, index) {
                              final user = _displayUsers[index];
                              final userId =
                                  (user['id'] ?? user['userId'])?.toString() ??
                                  "";
                              final isSelected = _selectedUserIds.contains(
                                userId,
                              );

                              return ListTile(
                                onTap: () => _toggleUser(userId),
                                leading: CircleAvatar(
                                  backgroundImage: user['avatar'] != null
                                      ? NetworkImage(user['avatar'])
                                      : null,
                                  backgroundColor: inputColor,
                                  child: user['avatar'] == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  user['name'] ?? 'User',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  user['headline'] ?? 'Connection',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? primaryBlue
                                      : Colors.white24,
                                ),
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isCreating || _nameController.text.isEmpty)
                        ? null
                        : _createGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryBlue.withOpacity(0.3),
                      shape: RoundedRectangleAttribute(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Create Group (${_selectedUserIds.length})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleAttribute(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color inputColor,
    IconData? prefixIcon,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white30, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// Fixed rounded corners helper
class RoundedRectangleAttribute extends RoundedRectangleBorder {
  const RoundedRectangleAttribute({super.borderRadius});
}
