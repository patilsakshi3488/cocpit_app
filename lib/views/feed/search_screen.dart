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
  List<String> _recentSearches = [];

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
        setState(() {
          _recentSearches = List<String>.from(jsonDecode(jsonStr));
        });
      }
    } catch (_) {}
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final cleanQuery = query.trim();

    setState(() {
      _recentSearches.remove(cleanQuery); // Remove duplicates
      _recentSearches.insert(0, cleanQuery); // Add to top
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5); // Limit to 5
      }
    });

    await AppSecureStorage.saveSearchHistory(jsonEncode(_recentSearches));
  }

  Future<void> _removeFromHistory(String query) async {
    setState(() {
      _recentSearches.remove(query);
    });
    await AppSecureStorage.saveSearchHistory(jsonEncode(_recentSearches));
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
                          onSubmitted: (val) =>
                              _addToHistory(val), // ✅ Save on Enter
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
        child: Text(_error!, style: TextStyle(color: Colors.red)),
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
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(_recentSearches[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => _removeFromHistory(_recentSearches[index]),
                  ),
                  onTap: () {
                    _controller.text = _recentSearches[index];
                    _search(_recentSearches[index]);
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
            // ✅ Only save valid, completed searches (User Name)
            _addToHistory(user.fullName);

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
