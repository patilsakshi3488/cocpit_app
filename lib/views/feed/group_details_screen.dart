import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/group_chat_service.dart';
import '../../services/secure_storage.dart';
import '../../services/profile_service.dart';
import '../../services/social_service.dart';
import '../../services/user_search_service.dart';
import 'dart:async';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final bool isAdmin;
  final VoidCallback onMembersChanged;
  final VoidCallback onLeave;

  const GroupDetailsScreen({
    super.key,
    required this.conversation,
    required this.isAdmin,
    required this.onMembersChanged,
    required this.onLeave,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final GroupChatService _groupService = GroupChatService();
  final ProfileService _profileService = ProfileService();
  bool _isLeaving = false;
  Map<String, dynamic> _groupDetails = {};
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _groupDetails = widget.conversation;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    _myUserId = await AppSecureStorage.getCurrentUserId();
    final fresh = await _groupService.getGroupDetails(
      widget.conversation['conversation_id'],
    );
    if (fresh != null && mounted) {
      setState(() => _groupDetails = fresh);
      _fetchMemberProfiles(fresh['members']);
    }
  }

  Future<void> _fetchMemberProfiles(List<dynamic>? members) async {
    if (members == null) return;
    bool stateChanged = false;

    // Create a NEW list to avoid modifying the read-only map directly if it came from certain sources
    List<dynamic> updatedMembers = List.from(members);

    for (var i = 0; i < updatedMembers.length; i++) {
      var member = updatedMembers[i];
      // Only fetch if name is missing or default "User"
      if (_getMemberName(member) == 'User') {
        final id = _getMemberId(member);
        if (id.isNotEmpty) {
          try {
            final profile = await _profileService.getUserProfile(id);
            if (profile != null && profile['user'] != null) {
              // Merge the fetched user details into the member object
              // ensuring we keep top-level existing keys but overwrite/add user info
              final userData = profile['user'];
              // If member was just an ID string or simple map, this makes it robust
              final Map<String, dynamic> newMemberData = member is Map
                  ? Map<String, dynamic>.from(member)
                  : {};

              // Ensure we have the ID preserved
              newMemberData['id'] ??= id;

              // Inject helpful keys for our _getMemberName parser
              newMemberData['name'] = userData['name'];
              newMemberData['avatar'] =
                  userData['avatar'] ?? userData['avatar_url'];
              newMemberData['user'] = userData;

              updatedMembers[i] = newMemberData;
              stateChanged = true;
            }
          } catch (e) {
            debugPrint("Failed to fetch profile for member $id: $e");
          }
        }
      }
    }

    if (stateChanged && mounted) {
      setState(() {
        // Deep copy of _groupDetails to ensure Flutter detects change if needed (though map mutation usually works)
        Map<String, dynamic> newDetails = Map.from(_groupDetails);
        newDetails['members'] = updatedMembers;
        _groupDetails = newDetails;
      });
    }
  }

  Future<void> _removeMember(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Member?"),
        content: Text(
          "Are you sure you want to remove $userName from the group?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _groupService.removeMember(
        widget.conversation['conversation_id'],
        userId,
      );
      if (success) {
        // Step 3: Sync - Re-fetch details after modification
        await _fetchDetails();
        widget.onMembersChanged();
      }
    }
  }

  // 🛠️ Parsing Helpers
  String _getMemberName(dynamic member) {
    if (member == null) return 'User';
    // 1. Direct key
    if (member['name'] != null && member['name'].toString().isNotEmpty) {
      return member['name'];
    }
    // 2. Nested user object
    if (member['user'] != null &&
        member['user']['name'] != null &&
        member['user']['name'].toString().isNotEmpty) {
      return member['user']['name'];
    }
    // 3. Username
    if (member['username'] != null &&
        member['username'].toString().isNotEmpty) {
      return member['username'];
    }
    // 4. Nested user object username
    if (member['user'] != null &&
        member['user']['username'] != null &&
        member['user']['username'].toString().isNotEmpty) {
      return member['user']['username'];
    }
    return 'User';
  }

  String? _getMemberAvatar(dynamic member) {
    if (member == null) return null;
    // 1. Direct key
    if (member['avatar'] != null && member['avatar'].toString().isNotEmpty) {
      return member['avatar'];
    }
    // 2. Nested user object
    if (member['user'] != null &&
        member['user']['avatar'] != null &&
        member['user']['avatar'].toString().isNotEmpty) {
      return member['user']['avatar'];
    }
    // 3. Profile Picture
    if (member['profile_picture'] != null &&
        member['profile_picture'].toString().isNotEmpty) {
      return member['profile_picture'];
    }
    return null;
  }

  String _getMemberId(dynamic member) {
    if (member == null) return '';
    // 1. Direct id
    if (member['id'] != null) return member['id'].toString();
    // 2. user_id
    if (member['user_id'] != null) return member['user_id'].toString();
    // 3. Nested user id
    if (member['user'] != null && member['user']['id'] != null) {
      return member['user']['id'].toString();
    }
    return '';
  }

  bool _isCurrentUserMember() {
    if (_groupDetails.isEmpty) return false;
    final members = _groupDetails['members'] as List<dynamic>? ?? [];
    return members.any((member) {
      final memberId = _getMemberId(member);
      return memberId == _myUserId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sort members: Admin first
    final adminId = _groupDetails['admin_id']?.toString();

    List<dynamic> members = List.from(_groupDetails['members'] as List? ?? []);
    members.sort((a, b) {
      final idA = _getMemberId(a);
      final idB = _getMemberId(b);
      if (idA == adminId) return -1; // a is admin, goes first
      if (idB == adminId) return 1; // b is admin, goes first
      return 0; // maintain relative order otherwise
    });

    final groupName =
        _groupDetails['conversation_name'] ??
        _groupDetails['group_name'] ??
        _groupDetails['title'] ??
        'Group Details';

    final groupAvatar =
        _groupDetails['avatar_url'] ??
        _groupDetails['group_avatar'] ??
        _groupDetails['avatar'] ??
        _groupDetails['icon'] ??
        _groupDetails['icon_url'];

    final bool amIAdmin = adminId == _myUserId || widget.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2235), // Dark modal background
      appBar: AppBar(
        title: const Text("Group Info"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        automaticallyImplyLeading:
            false, // Hide back button since we have close
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 24),
          // Group Identity
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                  child: groupAvatar != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(groupAvatar),
                        )
                      : Center(
                          child: Text(
                            (groupName.isNotEmpty ? groupName[0] : '?')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                ),
                if (amIAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null && mounted) {
                          final success = await _groupService.updateGroupAvatar(
                            widget.conversation['conversation_id'],
                            File(image.path),
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Group icon updated"),
                              ),
                            );
                            // Step 3: Sync - Re-fetch details immediately
                            await _fetchDetails();
                            widget.onMembersChanged();
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1E2235),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              groupName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              "${members.length} participants",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Members List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Members",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (amIAdmin)
                TextButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AddMemberDialog(
                        groupId: widget.conversation['conversation_id'],
                      ),
                    );
                    widget.onMembersChanged();
                    await _fetchDetails();
                  },
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text("Add Member"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...members.map((member) {
            final memberId = _getMemberId(member);
            final memberName = _getMemberName(member);
            final memberAvatar = _getMemberAvatar(member);
            final isThisMemberAdmin = memberId == adminId;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: memberAvatar != null
                    ? NetworkImage(memberAvatar)
                    : null,
                child: memberAvatar == null ? const Icon(Icons.person) : null,
              ),
              title: Text(memberName),
              subtitle: isThisMemberAdmin
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Admin",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : null,
              trailing: amIAdmin && !isThisMemberAdmin && memberId != _myUserId
                  ? IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeMember(memberId, memberName),
                    )
                  : null,
            );
          }).toList(),
          const SizedBox(height: 24),

          // Leave/Delete Group Section - Tab-like buttons
          // Only show if user is still a member
          if (_isCurrentUserMember()) ...[
            if (!amIAdmin) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLeaving ? null : _leaveGroupOnly,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Leave Group",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLeaving ? null : _leaveAndDeleteGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Leave & Delete",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (amIAdmin)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLeaving ? null : _deleteGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Leave & Delete Group",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _leaveGroupOnly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text(
          "You will no longer receive messages from this group, but it will remain in your chat list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLeaving = true);
      final success = await _groupService.leaveGroup(
        widget.conversation['conversation_id'],
      );
      if (mounted) {
        if (success) {
          // Trigger parent to reload group details and update membership
          widget.onMembersChanged();
          // Don't call widget.onLeave() - keep in chat list
          Navigator.pop(
            context,
            true,
          ); // Return true to signal parent to reload
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have left the group")),
          );
        } else {
          setState(() => _isLeaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to leave group")),
          );
        }
      }
    }
  }

  Future<void> _leaveAndDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave & Delete Group"),
        content: const Text(
          "You will leave the group and it will be removed from your chat list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Leave & Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLeaving = true);
      final success = await _groupService.leaveGroup(
        widget.conversation['conversation_id'],
      );
      if (mounted) {
        if (success) {
          widget.onLeave(); // Remove from chat list
          Navigator.pop(context);
        } else {
          setState(() => _isLeaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to leave group")),
          );
        }
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave & Delete Group"),
        content: const Text("This group will be deleted for all members."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLeaving = true);
      final success = await _groupService.deleteGroup(
        widget.conversation['conversation_id'],
      );
      if (mounted) {
        if (success) {
          widget.onLeave();
          Navigator.pop(context);
        } else {
          setState(() => _isLeaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete group")),
          );
        }
      }
    }
  }
}

class AddMemberDialog extends StatefulWidget {
  final String groupId;

  const AddMemberDialog({super.key, required this.groupId});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  final GroupChatService _groupService = GroupChatService();
  final SocialService _socialService = SocialService();

  List<Map<String, dynamic>> _displayUsers = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    try {
      final connections = await _socialService.getMyConnections();
      if (mounted) {
        setState(() {
          _displayUsers = connections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _loadConnections();
        return;
      }

      setState(() => _isLoading = true);
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
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _inviteUser(String userId) async {
    try {
      final success = await _groupService.inviteMember(widget.groupId, userId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Invitation sent")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to invite user")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark modal theme
    final backgroundColor = const Color(0xFF1E2235);
    final inputColor = const Color(0xFF262B44);
    final primaryBlue = const Color(0xFF5161B3);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Members",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            Container(
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white30,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayUsers.isEmpty
                  ? Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _displayUsers.length,
                      itemBuilder: (context, index) {
                        final user = _displayUsers[index];
                        final userId =
                            (user['id'] ?? user['userId'])?.toString() ?? "";

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
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
                          trailing: TextButton(
                            onPressed: () => _inviteUser(userId),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text("Invite"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
