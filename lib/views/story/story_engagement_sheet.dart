import 'package:flutter/material.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/views/story/story_comments_sheet.dart';
import 'package:cocpit_app/views/profile/public_profile_screen.dart';

class StoryEngagementSheet extends StatefulWidget {
  final Story story;
  final int initialTabIndex;
  final Map<String, dynamic>? initialData;

  const StoryEngagementSheet({
    super.key,
    required this.story,
    this.initialTabIndex = 0,
    this.initialData,
  });

  @override
  State<StoryEngagementSheet> createState() => _StoryEngagementSheetState();
}

class _StoryEngagementSheetState extends State<StoryEngagementSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _details;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTabIndex >= 0 && widget.initialTabIndex <= 2)
          ? widget.initialTabIndex
          : 0,
    );

    if (widget.initialData != null) {
      _details = widget.initialData;
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await StoryService.getStoryDetails(widget.story.storyId);
      if (!mounted) return;
      setState(() {
        _details = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _details == null) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Counts
    final viewCount = _details?['viewCount'] ?? widget.story.viewCount;
    final likeCount = _details?['likeCount'] ?? widget.story.likeCount;
    final commentCount =
        widget.story.commentCount; // Or from details if available

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: "Views ($viewCount)"),
              Tab(text: "Likes ($likeCount)"),
              Tab(text: "Comments ($commentCount)"),
            ],
          ),

          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Views Tab
                widget.story.isAuthor
                    ? _UserList(
                        users: _details?['viewers'] ?? [],
                        emptyMsg: "No views yet",
                      )
                    : const Center(
                        child: Text(
                          "Viewers are private",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),

                // 2. Likes Tab
                _UserList(
                  users: _details?['likes'] ?? _details?['reporters'] ?? [],
                  emptyMsg: "No likes yet",
                ),

                // 3. Comments Tab
                StoryCommentsSheet(
                  storyId: widget.story.storyId,
                  initialCount: commentCount,
                  isStoryAuthor: widget.story.isAuthor,
                  embedInSheet: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<dynamic> users;
  final String emptyMsg;

  const _UserList({required this.users, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final v = users[index];
        final userObj = v is Map ? (v['user'] ?? v) : {};

        final name =
            userObj['name'] ??
            userObj['full_name'] ??
            userObj['username'] ??
            "User";
        final avatar =
            userObj['avatar'] ??
            userObj['avatar_url'] ??
            userObj['profile_picture'];
        final userId =
            userObj['user_id']?.toString() ??
            userObj['_id']?.toString() ??
            userObj['id']?.toString();

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: userId != null ? () => _navToProfile(context, userId) : null,
            child: CircleAvatar(
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              backgroundColor: Colors.white10,
              child: avatar == null
                  ? const Icon(Icons.person, color: Colors.white70)
                  : null,
            ),
          ),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          onTap: userId != null ? () => _navToProfile(context, userId) : null,
        );
      },
    );
  }

  void _navToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)),
    );
  }
}
