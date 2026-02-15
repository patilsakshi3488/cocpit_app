import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/secure_storage.dart';
import 'views/feed/home_screen.dart';
import 'views/login/signin_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await AppSecureStorage.getAccessToken();

      if (token == null) {
        _goToLogin();
        return;
      }

      // 1️⃣ Try getting current user
      final me = await authService.getMe();
      if (me != null) {
        _goToHome();
        return;
      }

      // 2️⃣ If failing, try refreshing
      final refreshed = await authService.refreshAccessToken();
      if (refreshed != null) {
        // Retry getMe after refresh
        final meRetry = await authService.getMe();
        if (meRetry != null) {
          _goToHome();
          return;
        }
      }

      // ❌ If all fails
      _goToLogin();
    } catch (e) {
      debugPrint("AuthGate Error: $e");
      // 🛡️ Safety net: Always go to login if something crashes
      _goToLogin();
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}










//user_search_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../config/api_config.dart';
// import '../models/search_user.dart';
//
// class UserSearchService {
//   static Future<List<SearchUser>> searchUsers({
//     required String query,
//     required String token,
//   }) async {
//     final uri = Uri.parse(
//       "${ApiConfig.searchUsers}?q=${Uri.encodeQueryComponent(query)}",
//     );
//
//     final response = await http.get(
//       uri,
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final List data = json.decode(response.body);
//       return data.map((e) => SearchUser.fromJson(e)).toList();
//     } else {
//       throw Exception("Failed to search users");
//     }
//   }
// }


//home_screen.dart
// import 'package:flutter/material.dart';
// import 'dart:async';
//
// import '../../models/search_user.dart';
// import '../../services/user_search_service.dart';
// import '../../services/secure_storage.dart';
// import '../profile/profile_screen.dart';
// import '../profile/public_profile_screen.dart';
//
// import 'chat_screen.dart';
// import 'notification_screen.dart';
// import '../bottom_navigation.dart';
// import 'create_career_moment_screen.dart';
// import 'career_moment_viewer.dart';
// import '../../widgets/app_top_bar.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   bool showTop = false;
//   late TextEditingController _searchController;
//   late FocusNode _searchFocusNode;
//   final LayerLink _layerLink = LayerLink();
//   OverlayEntry? _overlayEntry;
//
//   // 🔽 SEARCH STATE
//   List<SearchUser> _searchResults = [];
//   bool _isSearching = false;
//   bool _hasError = false;
//   String _lastQuery = "";
//   Timer? _debounce;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController = TextEditingController();
//     _searchFocusNode = FocusNode();
//     _searchFocusNode.addListener(_onSearchFocusChange);
//   }
//
//   void _onSearchFocusChange() {
//     if (_searchFocusNode.hasFocus) {
//       if (_searchController.text.isNotEmpty) {
//         _showSearchOverlay();
//       }
//     } else {
//       // Delay removal to allow tap events on overlay to register
//       Future.delayed(const Duration(milliseconds: 200), () {
//         if (mounted && !_searchFocusNode.hasFocus) {
//           _closeOverlay();
//         }
//       });
//     }
//   }
//
//   void _closeOverlay() {
//     if (_overlayEntry != null) {
//       _overlayEntry?.remove();
//       _overlayEntry = null;
//     }
//   }
//
//   /// Reset all search-related state to defaults
//   void resetSearchState() {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _closeOverlay();
//     setState(() {
//       _searchController.clear();
//       _searchResults = [];
//       _isSearching = false;
//       _hasError = false;
//       _lastQuery = "";
//     });
//   }
//
//   void _onSearchChanged(String query) {
//     _lastQuery = query;
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//
//     if (query.trim().isEmpty) {
//       setState(() {
//         _searchResults = [];
//         _isSearching = false;
//         _hasError = false;
//       });
//       _closeOverlay();
//       return;
//     }
//
//     _debounce = Timer(const Duration(milliseconds: 500), () async {
//       if (query.trim().isEmpty) return;
//
//       if (mounted) {
//         setState(() {
//           _isSearching = true;
//           _hasError = false;
//         });
//         _showSearchOverlay();
//       }
//
//       try {
//         final token = await AppSecureStorage.getAccessToken();
//         if (token == null) return;
//
//         final results = await UserSearchService.searchUsers(
//           query: query,
//           token: token,
//         );
//
//         if (mounted && _lastQuery == query) {
//           setState(() {
//             _searchResults = results;
//             _isSearching = false;
//           });
//           _showSearchOverlay();
//         }
//       } catch (e) {
//         debugPrint("❌ Search API Error: $e");
//         if (mounted) {
//           setState(() {
//             _isSearching = false;
//             _hasError = true;
//           });
//           _showSearchOverlay();
//         }
//       }
//     });
//   }
//
//   void _showSearchOverlay() {
//     // MANDATORY: Remove existing before inserting new
//     _closeOverlay();
//
//     _overlayEntry = _createSearchOverlayEntry();
//     if (_overlayEntry != null) {
//       Overlay.of(context).insert(_overlayEntry!);
//     }
//   }
//
//   OverlayEntry _createSearchOverlayEntry() {
//     final theme = Theme.of(context);
//     final query = _searchController.text.trim();
//
//     return OverlayEntry(
//       builder: (context) => Positioned(
//         width: MediaQuery.of(context).size.width - 32,
//         child: CompositedTransformFollower(
//           link: _layerLink,
//           offset: const Offset(0, 50),
//           showWhenUnlinked: false,
//           child: Material(
//             elevation: 8,
//             borderRadius: BorderRadius.circular(16),
//             color: theme.colorScheme.surface,
//             child: Container(
//               constraints: const BoxConstraints(maxHeight: 400),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: theme.dividerColor),
//               ),
//               child: _buildOverlayContent(theme, query),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOverlayContent(ThemeData theme, String query) {
//     if (_isSearching) {
//       return const Padding(
//         padding: EdgeInsets.all(32.0),
//         child: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (_hasError) {
//       return _messageItem(
//         theme,
//         "Something went wrong. Try again",
//         Icons.error_outline,
//         onAction: () => _onSearchChanged(query),
//         actionLabel: "Retry",
//       );
//     }
//
//     if (query.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     if (_searchResults.isEmpty) {
//       return _messageItem(theme, "User not found for '$query'", Icons.search_off);
//     }
//
//     return _buildResultsList(theme);
//   }
//
//   Widget _buildResultsList(ThemeData theme) {
//     return ListView(
//       shrinkWrap: true,
//       padding: EdgeInsets.zero,
//       children: _searchResults.take(10).map((user) => _userTile(theme, user)).toList(),
//     );
//   }
//
//   Widget _userTile(ThemeData theme, SearchUser user) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
//             ? NetworkImage(user.avatarUrl!)
//             : const AssetImage('lib/images/profile.png') as ImageProvider,
//       ),
//       title: Text(user.fullName, style: theme.textTheme.titleSmall),
//       subtitle: (user.headline ?? user.accountType) != null
//           ? Text(user.headline ?? user.accountType!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
//           : null,
//       onTap: () async {
//         // 1️⃣ VALIDATION: Block if ID is invalid
//         if (user.id.isEmpty) {
//           debugPrint("❌ UUID Safety: Invalid User ID blocked.");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Profile unavailable"))
//           );
//           return;
//         }
//
//         // 2️⃣ OVERLAY + NAVIGATION SEQUENCE
//         _closeOverlay();
//         FocusScope.of(context).unfocus();
//
//         // Ensure UI thread clears before navigation
//         await Future.microtask(() {});
//
//         if (mounted) {
//           // 3️⃣ STATE RESET ON RETURN
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: user.id)),
//           ).then((_) {
//             if (mounted) resetSearchState();
//           });
//         }
//       },
//     );
//   }
//
//   Widget _messageItem(ThemeData theme, String text, IconData icon, {VoidCallback? onAction, String? actionLabel}) {
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: theme.textTheme.bodySmall?.color, size: 32),
//           const SizedBox(height: 12),
//           Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
//           if (onAction != null && actionLabel != null) ...[
//             const SizedBox(height: 12),
//             TextButton(onPressed: onAction, child: Text(actionLabel)),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // --- Static UI Data ---
//   final List<Map<String, dynamic>> careerMoments = [
//     {
//       'name': 'You',
//       'isMine': true,
//       'stories': [
//         {'image': 'lib/images/profile.png', 'text': 'Just sharing my latest update with my close friends!', 'time': '1m ago'},
//       ],
//       'profile': 'lib/images/profile.png',
//       'image': 'lib/images/profile.png',
//     },
//     {
//       'name': 'Mike Torres',
//       'isMine': false,
//       'image': 'lib/images/story1.png',
//       'profile': 'lib/images/profile2.jpg',
//       'stories': [
//         {'image': 'lib/images/story1.png', 'text': 'Sneak peek of our latest feature!', 'time': '6h ago'},
//       ],
//     },
//     {
//       'name': 'James Wilson',
//       'isMine': false,
//       'image': 'lib/images/story4.png',
//       'profile': 'lib/images/profile3.jpg',
//       'stories': [
//         {'image': 'lib/images/story4.png', 'text': 'Insights from our data analysis project.', 'time': '8h ago'},
//       ],
//     },
//   ];
//
//   final List<Map<String, dynamic>> _posts = [
//     {
//       'id': '1',
//       'name': 'Sarah Chen',
//       'title': 'UX Designer at Design Studio',
//       'time': '2h ago',
//       'text': "🎨 Just launched our new design system!",
//       'image': 'lib/images/post1.jpg',
//       'profile': 'lib/images/profile3.jpg',
//       'likes': 234,
//       'isLiked': false,
//       'isPrivate': false,
//       'comments_count': 47,
//       'shares': 12,
//     },
//     {
//       'id': '2',
//       'name': 'Sally Liang',
//       'title': 'Senior Financial Analyst',
//       'time': '1d ago',
//       'text': "Deep dive into data analysis trends for 2024.",
//       'image': null,
//       'profile': 'lib/images/profile4.jpg',
//       'likes': 1200,
//       'isLiked': false,
//       'isPrivate': false,
//       'comments_count': 15,
//       'shares': 8,
//     },
//     {
//       'id': 'suggested',
//       'type': 'suggested',
//     },
//   ];
//
//   final List<Map<String, dynamic>> suggestedUsers = [
//     {
//       'name': 'Sarah Williams',
//       'role': 'UX Designer',
//       'followers': '2.3k',
//       'profile': 'lib/images/profile3.jpg',
//       'isVerified': true,
//     },
//     {
//       'name': 'Michael Jordan',
//       'role': 'Software Engineer',
//       'followers': '1.8k',
//       'profile': 'lib/images/profile2.jpg',
//       'isVerified': false,
//     },
//   ];
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _overlayEntry?.remove();
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppTopBar(
//         searchType: SearchType.feed,
//         controller: _searchController,
//         focusNode: _searchFocusNode,
//         onChanged: _onSearchChanged,
//         layerLink: _layerLink,
//       ),
//       body: ListView(
//         children: [
//           _storiesHeader(theme),
//           _careerMomentsBar(theme),
//           const SizedBox(height: 20),
//           _topRecentToggle(theme),
//           Divider(color: theme.dividerColor, height: 1),
//           ..._posts.map((post) {
//             if (post['type'] == 'suggested') {
//               return _suggestedForYouSection(theme);
//             }
//             return _postView(post, theme);
//           }),
//         ],
//       ),
//       bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
//     );
//   }
//
//   Widget _storiesHeader(ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text("Stories", style: theme.textTheme.titleLarge),
//           Text("View All", style: TextStyle(color: theme.primaryColor, fontSize: 14)),
//         ],
//       ),
//     );
//   }
//
//   Widget _careerMomentsBar(ThemeData theme) {
//     double itemWidth = MediaQuery.of(context).size.width > 600 ? 150 : 120;
//
//     return SizedBox(
//       height: 180,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         itemCount: careerMoments.length,
//         itemBuilder: (context, index) {
//           final m = careerMoments[index];
//           return GestureDetector(
//             onTap: () {
//               if (m['isMine']) {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCareerMomentScreen()));
//               } else {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => CareerMomentViewer(users: careerMoments, initialUserIndex: index)));
//               }
//             },
//             child: Container(
//               width: itemWidth,
//               margin: const EdgeInsets.only(right: 12),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 image: !m['isMine'] ? DecorationImage(image: AssetImage(m['image']), fit: BoxFit.cover) : null,
//                 color: m['isMine'] ? theme.primaryColor : theme.cardColor,
//               ),
//               child: Stack(
//                 children: [
//                   if (m['isMine'])
//                     Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(color: theme.colorScheme.onPrimary.withValues(alpha: 0.2), shape: BoxShape.circle),
//                             child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 30),
//                           ),
//                           const SizedBox(height: 12),
//                           Text("Your Update", style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
//                         ],
//                       ),
//                     ),
//                   if (!m['isMine'])
//                     Positioned(
//                       bottom: 8, left: 0, right: 0,
//                       child: Column(
//                         children: [
//                           CircleAvatar(radius: 18, backgroundColor: theme.primaryColor, child: CircleAvatar(radius: 16, backgroundImage: AssetImage(m['profile']))),
//                           const SizedBox(height: 4),
//                           Text(m['name'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _topRecentToggle(ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           _togglePill("Top", showTop, theme, () => setState(() => showTop = true)),
//           const SizedBox(width: 12),
//           _togglePill("Recent", !showTop, theme, () => setState(() => showTop = false)),
//         ],
//       ),
//     );
//   }
//
//   Widget _togglePill(String text, bool selected, ThemeData theme, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//         decoration: BoxDecoration(color: selected ? theme.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(10)),
//         child: Text(text, style: TextStyle(color: selected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
//
//   Widget _suggestedForYouSection(ThemeData theme) {
//     double cardWidth = MediaQuery.of(context).size.width > 600 ? 250 : 180;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Text("Suggested for you", style: theme.textTheme.titleLarge),
//         ),
//         SizedBox(
//           height: 240,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             itemCount: suggestedUsers.length,
//             itemBuilder: (context, index) {
//               final user = suggestedUsers[index];
//               return Container(
//                 width: cardWidth,
//                 margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: theme.cardColor,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: theme.dividerColor),
//                 ),
//                 child: Column(
//                   children: [
//                     CircleAvatar(radius: 40, backgroundImage: AssetImage(user['profile'])),
//                     const SizedBox(height: 12),
//                     Text(user['name'], style: theme.textTheme.titleSmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
//                     Text(user['role'], style: theme.textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
//                     const Spacer(),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {},
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: theme.primaryColor,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                         child: const Text("Follow", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _postView(Map<String, dynamic> post, ThemeData theme) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(radius: 24, backgroundImage: AssetImage(post['profile'])),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(post['name'], style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
//                         Text(post['title'], style: theme.textTheme.bodySmall),
//                         Text(post['time'], style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(post['text'], style: theme.textTheme.bodyMedium),
//               if (post['image'] != null) ...[
//                 const SizedBox(height: 12),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.asset(post['image'], fit: BoxFit.cover, width: double.infinity, height: 200),
//                 ),
//               ],
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   _postAction(Icons.favorite_border, post['likes'].toString(), theme),
//                   const SizedBox(width: 20),
//                   _postAction(Icons.chat_bubble_outline, post['comments_count'].toString(), theme),
//                   const Spacer(),
//                   Icon(Icons.bookmark_border, color: theme.iconTheme.color?.withValues(alpha: 0.6)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Divider(color: theme.dividerColor, height: 1),
//       ],
//     );
//   }
//
//   Widget _postAction(IconData icon, String count, ThemeData theme) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: theme.iconTheme.color?.withValues(alpha: 0.6)),
//         const SizedBox(width: 6),
//         Text(count, style: theme.textTheme.bodySmall),
//       ],
//     );
//   }
// }
