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
      initialIndex: widget.initialTabIndex,
    );

    if (widget.initialData != null) {
      _details = widget.initialData;
      _loading = false;
    } else {
      _load();
    }
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
    // Determine tabs visibility based on isAuthor?
    // Usually standard users can't see Viewers list, only count.
    // But specific requirement says "One sheet".
    // For non-authors:
    // - Views tab: Maybe hide or show just count?
    // - Likes tab: Usually visible (or just count)
    // - Comments tab: Visible
    // The user provided code creates 3 tabs regardless. I will follow that but handle empty/permission states inside the list.

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text:
                    "Views ${_details != null ? '(${_details!['viewCount'] ?? 0})' : ''}",
              ),
              Tab(
                text:
                    "Likes ${_details != null ? '(${_details!['likeCount'] ?? 0})' : ''}",
              ),
              Tab(
                text:
                    "Comments ${_details != null ? '(${widget.story.commentCount})' : ''}",
              ),
            ],
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Views Tab
                      widget.story.isAuthor
                          ? _UserList(
                              users: _details!['viewers'] ?? [],
                              emptyMsg: "No views yet",
                            )
                          : const Center(
                              child: Text(
                                "Viewers are private",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),

                      // Likes Tab
                      _UserList(
                        users:
                            _details!['likes'] ?? _details!['reporters'] ?? [],
                        emptyMsg: "No likes yet",
                      ),

                      // Comments Tab
                      StoryCommentsSheet(
                        storyId: widget.story.storyId,
                        initialCount: widget.story.commentCount,
                        isStoryAuthor: widget.story.isAuthor,
                        embedInSheet:
                            true, // Helper to adjust padding if needed
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
            userObj['user_name'] ??
            userObj['username'] ??
            "User";

        final avatar =
            userObj['avatar'] ??
            userObj['avatar_url'] ??
            userObj['profile_picture'] ??
            userObj['user_avatar'];

        final userId =
            userObj['user_id']?.toString() ??
            userObj['author_id']?.toString() ??
            userObj['id']?.toString() ??
            userObj['_id']?.toString();

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: userId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: userId),
                      ),
                    );
                  }
                : null,
            child: CircleAvatar(
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              backgroundColor: Colors.white10,
              child: avatar == null
                  ? const Icon(Icons.person, color: Colors.white70)
                  : null,
            ),
          ),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          onTap: userId != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(userId: userId),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}
