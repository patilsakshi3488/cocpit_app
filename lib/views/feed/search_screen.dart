import 'package:flutter/material.dart';
import 'dart:convert'; // Added for JSON encoding
import 'package:cocpit_app/services/user_search_service.dart';
import 'package:cocpit_app/services/secure_storage.dart';
import 'package:cocpit_app/models/search_user.dart';
import 'package:cocpit_app/views/profile/public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SearchUser> _results = [];
  bool _isLoading = false;
  String? _error;

  // Real persistent history
  List<SearchUser> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final jsonStr = await AppSecureStorage.getSearchHistory();
      if (jsonStr != null) {
        final List<dynamic> rawList = jsonDecode(jsonStr);
        setState(() {
          _recentSearches = rawList.map((e) {
            // BACKWARD COMPATIBILITY: Handle old String history
            if (e is String) {
              return SearchUser(id: '', fullName: e);
            }
            return SearchUser.fromJson(e);
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _addToHistory(SearchUser user) async {
    if (user.fullName.trim().isEmpty) return;

    setState(() {
      // Remove duplicates by ID (preferred) or Name
      _recentSearches.removeWhere(
        (u) => u.id == user.id || (u.id.isEmpty && u.fullName == user.fullName),
      );

      _recentSearches.insert(0, user); // Add to top
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5); // Limit to 5
      }
    });

    final jsonList = _recentSearches.map((u) => u.toJson()).toList();
    await AppSecureStorage.saveSearchHistory(jsonEncode(jsonList));
  }

  Future<void> _removeFromHistory(SearchUser user) async {
    setState(() {
      _recentSearches.remove(user);
    });
    final jsonList = _recentSearches.map((u) => u.toJson()).toList();
    await AppSecureStorage.saveSearchHistory(jsonEncode(jsonList));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AppSecureStorage.getAccessToken();
      if (token == null) return;

      final results = await UserSearchService.searchUsers(
        query: query,
        token: token,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
        // REMOVED: Do not save history on every keystroke
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load results";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.only(left: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.textTheme.bodySmall?.color,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (val) => _search(val),
                          onSubmitted: (val) {
                            // Handle manual text entry search if needed, currently only tapping results saves history
                            _search(val);
                          },
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: "Search",
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _controller.clear();
                                      _search("");
                                      _loadHistory(); // Reload history on clear
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    // Show Recent Searches if query is empty
    if (_controller.text.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Recent",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final historyItem = _recentSearches[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: historyItem.avatarUrl != null
                        ? NetworkImage(historyItem.avatarUrl!)
                        : null,
                    radius: 16,
                    child: historyItem.avatarUrl == null
                        ? const Icon(Icons.history, size: 16)
                        : null,
                  ),
                  title: Text(historyItem.fullName),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => _removeFromHistory(historyItem),
                  ),
                  onTap: () {
                    // 🚀 NAVIGATE DIRECTLY
                    // If ID is missing (legacy string history), just populate text
                    if (historyItem.id.isEmpty) {
                      _controller.text = historyItem.fullName;
                      _search(historyItem.fullName);
                    } else {
                      // Move to top of history logic if desired, or just navigate
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(userId: historyItem.id),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // Show Results
    if (_results.isEmpty) {
      return Center(
        child: Text(
          "No results found",
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemBuilder: (context, index) {
        final user = _results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(user.headline ?? "No headline"),
          onTap: () {
            // ✅ Save User Object to History
            _addToHistory(user);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(userId: user.id),
              ),
            );
          },
        );
      },
    );
  }
}
