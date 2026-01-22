import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';

// ==========================================
// MODELS: Ensuring type-safety and logic
// ==========================================
class PollOption {
  final String id;
  final String text;
  final int voteCount;

  PollOption({required this.id, required this.text, required this.voteCount});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['option_id']?.toString() ?? '',
      text: json['option_text'] ?? '',
      voteCount: int.tryParse(json['vote_count'].toString()) ?? 0,
    );
  }

  PollOption copyWith({int? voteCount}) {
    return PollOption(
      id: id,
      text: text,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}

// class PollOption {
//   final int id;
//   final String text;
//   final int voteCount;
//
//   PollOption({required this.id, required this.text, required this.voteCount});
//
//   factory PollOption.fromJson(Map<String, dynamic> json) {
//     return PollOption(
//       id: _asInt(json['option_id']),
//       text: json['option_text'] ?? "",
//       voteCount: _asInt(json['vote_count']),
//     );
//   }
//
//   static int _asInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
// }

class PollModel {
  final String id;
  final List<PollOption> options;
  final String? userVote;
  final bool isActive;
  final String duration;

  PollModel({
    required this.id,
    required this.options,
    required this.userVote,
    required this.isActive,
    required this.duration,
  });

  /// Derived like website
  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List)
        .map((o) => PollOption.fromJson(o))
        .toList();

    return PollModel(
      id: json['poll_id']?.toString() ?? '',
      options: options,
      userVote: json['user_vote']?.toString(),
      isActive: json['is_active'] == true,
      duration: json['duration']?.toString() ?? "0",
    );
  }

  PollModel copyWith({List<PollOption>? options, String? userVote}) {
    return PollModel(
      id: id,
      options: options ?? this.options,
      userVote: userVote,
      isActive: isActive,
      duration: duration,
    );
  }
}

// class PollModel {
//   final int id;
//   final List<PollOption> options;
//   final int totalVotes;
//   final int? userVote;
//   final bool isActive;
//   final String duration;
//
//   PollModel({
//     required this.id,
//     required this.options,
//     required this.totalVotes,
//     this.userVote,
//     required this.isActive,
//     required this.duration,
//   });
//
//   factory PollModel.fromJson(Map<String, dynamic> json) {
//     final options = (json['options'] as List)
//         .map((o) => PollOption.fromJson(o))
//         .toList();
//
//     // 🔥 DERIVE total votes if backend does not send it
//     final derivedTotalVotes = options.fold<int>(
//       0,
//           (sum, opt) => sum + opt.voteCount,
//     );
//
//     return PollModel(
//       id: int.tryParse(json['poll_id'].toString()) ?? 0,
//       options: options,
//       totalVotes: json['total_votes'] != null
//           ? int.tryParse(json['total_votes'].toString()) ?? derivedTotalVotes
//           : derivedTotalVotes,
//       userVote: json['user_vote'] == null
//           ? null
//           : int.tryParse(json['user_vote'].toString()),
//       isActive: json['is_active'] == true,
//       duration: json['duration']?.toString() ?? "0",
//     );
//   }
//
// }

// ==========================================
// WIDGET: React-Parity Implementation
// ==========================================
class PollWidget extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> poll;
  final Function(Map<String, dynamic>)? onPollUpdated;

  const PollWidget({
    super.key,
    required this.postId,
    required this.poll,
    this.onPollUpdated,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  late PollModel _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _data = PollModel.fromJson(widget.poll);
  }

  // Sync state if the parent rebuilds (React-like props handling)
  @override
  void didUpdateWidget(PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.poll != oldWidget.poll) {
      setState(() => _data = PollModel.fromJson(widget.poll));
    }
  }

  Future<void> _onVotePressed(String selectedId) async {
    print(
      "DEBUG: _onVotePressed id=$selectedId. isActive=${_data.isActive}, isLoading=$_isLoading",
    );
    if (_isLoading || !_data.isActive) return;

    final previous = _data;
    final previousVote = _data.userVote;
    print("DEBUG: previousVote=$previousVote");

    setState(() {
      _isLoading = true;

      final updatedOptions = _data.options.map((opt) {
        if (opt.id == selectedId) {
          final newCount = previousVote == selectedId
              ? opt.voteCount - 1
              : opt.voteCount + 1;
          print(
            "DEBUG: Updating Option ${opt.id}: ${opt.voteCount} -> $newCount",
          );
          return opt.copyWith(voteCount: newCount);
        }

        if (opt.id == previousVote) {
          final newCount = opt.voteCount - 1;
          print(
            "DEBUG: Decrementing Prev Option ${opt.id}: ${opt.voteCount} -> $newCount",
          );
          return opt.copyWith(voteCount: newCount);
        }

        return opt;
      }).toList();

      _data = _data.copyWith(
        options: updatedOptions,
        userVote: previousVote == selectedId ? null : selectedId,
      );
      print(
        "DEBUG: Optimistic State: userVote=${_data.userVote}, totalVotes=${_data.totalVotes}",
      );
    });

    try {
      if (previousVote == selectedId) {
        print("DEBUG: calling DELETE API");
        await ApiClient.delete("/post/${widget.postId}/poll/vote");
      } else {
        print("DEBUG: calling POST API");
        await ApiClient.post(
          "/post/${widget.postId}/poll/vote",
          body: {"option_id": selectedId},
        );
      }

      print("DEBUG: fetching fresh POll");
      final res = await ApiClient.get("/post/${widget.postId}");
      print("DEBUG: fetch status ${res.statusCode}");
      if (mounted && res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded["poll"] != null) {
          print("DEBUG: New Poll Data: ${decoded["poll"]}");
          setState(() {
            _data = PollModel.fromJson(decoded["poll"]);
          });
          widget.onPollUpdated?.call(decoded["poll"]);
        }
      }
    } catch (e) {
      print("DEBUG: Error $e");
      if (mounted) setState(() => _data = previous);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // /// Core Logic: Optimistic UI with Mathematical Consistency
  // Future<void> _onVotePressed(int selectedId) async {
  //   if (_isLoading || !_data.isActive) return;
  //
  //   final previousData = _data;
  //   final int? previousVote = _data.userVote;
  //
  //   // --- OPTIMISTIC UPDATE CALCULATION ---
  //   setState(() {
  //     _isLoading = true;
  //
  //     int totalVoteChange = 0;
  //     if (previousVote == null) {
  //       totalVoteChange = 1; // First time voting
  //     } else if (previousVote == selectedId) {
  //       totalVoteChange = -1; // Deselecting current vote
  //     }
  //     // Note: If switching from Option A to Option B, totalVoteChange is 0.
  //
  //     final List<PollOption> optimsticOptions = _data.options.map((opt) {
  //       int newCount = opt.voteCount;
  //
  //       // Logic for the clicked option
  //       if (opt.id == selectedId) {
  //         newCount += (previousVote == selectedId) ? -1 : 1;
  //       }
  //       // Logic for the previously selected option (if switching)
  //       else if (opt.id == previousVote) {
  //         newCount -= 1;
  //       }
  //
  //       return PollOption(id: opt.id, text: opt.text, voteCount: newCount);
  //     }).toList();
  //
  //     _data = PollModel(
  //       id: _data.id,
  //       options: optimsticOptions,
  //       totalVotes: _data.totalVotes + totalVoteChange,
  //       userVote: previousVote == selectedId ? null : selectedId,
  //       isActive: _data.isActive,
  //       duration: _data.duration,
  //     );
  //   });
  //
  //   // --- API CALL ---
  //   try {
  //     if (previousVote == selectedId) {
  //       await ApiClient.delete("/post/${widget.postId}/poll/vote");
  //     } else {
  //       await ApiClient.post("/post/${widget.postId}/poll/vote", body: {"option_id": selectedId});
  //     }
  //
  //     // Final Sync (Source of Truth)
  //     final res = await ApiClient.get("/post/${widget.postId}");
  //     if (res.statusCode == 200 && mounted) {
  //       final decoded = jsonDecode(res.body);
  //       if (decoded["poll"] != null) {
  //         setState(() => _data = PollModel.fromJson(decoded["poll"]));
  //       }
  //     }
  //   } catch (e) {
  //     // Rollback on network failure
  //     if (mounted) setState(() => _data = previousData);
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          ..._data.options.map((opt) => _buildOptionRow(opt)),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildOptionRow(PollOption opt) {
    final bool isSelected = _data.userVote == opt.id;
    final bool showResults = _data.userVote != null || !_data.isActive;

    // Percentage calculation
    final double percent = _data.totalVotes > 0
        ? (opt.voteCount / _data.totalVotes)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _onVotePressed(opt.id),
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Track background
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Progress Fill
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: 48,
                  width: showResults ? constraints.maxWidth * percent : 0,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
            // Labels
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt.text,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    if (showResults)
                      Text(
                        "${(percent * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _data.isActive ? "${_data.duration}d left" : "Poll ended",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _data.isActive ? Colors.grey : Colors.redAccent,
          ),
        ),
        Row(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Text(
              "${_data.totalVotes} votes",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../services/api_client.dart';
//
// class PollWidget extends StatefulWidget {
//   final int postId;
//   final Map<String, dynamic> poll;
//
//   const PollWidget({
//     super.key,
//     required this.postId,
//     required this.poll,
//   });
//
//   @override
//   State<PollWidget> createState() => _PollWidgetState();
// }
//
// class _PollWidgetState extends State<PollWidget> {
//   late Map<String, dynamic> poll;
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     poll = Map<String, dynamic>.from(widget.poll);
//   }
//
//   int asInt(dynamic v) {
//     if (v == null) return 0;
//     if (v is int) return v;
//     if (v is double) return v.toInt();
//     return int.tryParse(v.toString()) ?? 0;
//   }
//
//   Future<void> _onVote(int optionId) async {
//     if (poll["is_active"] != true) return;
//
//     final postId = widget.postId;
//     final previousPoll = Map<String, dynamic>.from(poll);
//     final int? previousVote = poll["user_vote"] == null ? null : asInt(poll["user_vote"]);
//
//     // -------------------------------
//     // 1️⃣ Optimistic UI update
//     // -------------------------------
//     final updatedOptions = (poll["options"] as List).map((o) {
//       final opt = Map<String, dynamic>.from(o);
//
//       if (asInt(opt["option_id"]) == optionId) {
//         opt["vote_count"] += (previousVote == optionId) ? -1 : 1;
//       } else if (asInt(opt["option_id"]) == previousVote) {
//         opt["vote_count"] -= 1;
//       }
//
//       return opt;
//     }).toList();
//
//     final optimisticPoll = {
//       ...poll,
//       "options": updatedOptions,
//       "user_vote": previousVote == optionId ? null : optionId,
//       "total_votes": updatedOptions.fold<int>(
//         0,
//         (sum, o) => sum + asInt(o["vote_count"]),
//       ),
//     };
//
//     setState(() {
//       poll = optimisticPoll;
//       isLoading = true;
//     });
//
//     // -------------------------------
//     // 2️⃣ Backend persistence
//     // -------------------------------
//     try {
//       if (previousVote == optionId) {
//         await ApiClient.delete("/post/$postId/poll/vote");
//       } else {
//         await ApiClient.post(
//           "/post/$postId/poll/vote",
//           body: {"option_id": optionId},
//         );
//       }
//
//       // -------------------------------
//       // 3️⃣ FINAL source of truth
//       // -------------------------------
//       final res = await ApiClient.get("/post/$postId");
//       if (res.statusCode == 200) {
//         final decoded = jsonDecode(res.body);
//         if (mounted && decoded["poll"] != null) {
//           setState(() {
//             poll = Map<String, dynamic>.from(decoded["poll"]);
//           });
//         }
//       }
//     } catch (e) {
//       // -------------------------------
//       // 4️⃣ Revert on failure
//       // -------------------------------
//       if (mounted) {
//         setState(() => poll = previousPoll);
//       }
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final options = poll["options"] as List;
//     final int totalVotes = asInt(poll["total_votes"]);
//     final int? votedOptionId =
//         poll["user_vote"] == null ? null : asInt(poll["user_vote"]);
//     final bool isEnded = poll["is_active"] != true;
//
//     return Container(
//       margin: const EdgeInsets.only(top: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Theme.of(context).dividerColor),
//       ),
//       child: Column(
//         children: [
//           ...options.map((opt) {
//             final int optionId = asInt(opt["option_id"]);
//             final int votes = asInt(opt["vote_count"]);
//             final int percentage =
//                 totalVotes > 0 ? ((votes / totalVotes) * 100).round() : 0;
//
//             final bool isSelected = votedOptionId == optionId;
//             final bool isDisabled = isLoading || isEnded;
//
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 6),
//               child: GestureDetector(
//                 onTap: isDisabled ? null : () => _onVote(optionId),
//                 child: Stack(
//                   children: [
//                     Container(
//                       height: 48,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: isSelected
//                             ? Theme.of(context)
//                                 .primaryColor
//                                 .withOpacity(0.15)
//                             : Theme.of(context)
//                                 .dividerColor
//                                 .withOpacity(0.1),
//                         border: Border.all(
//                           color: isSelected
//                               ? Theme.of(context)
//                                   .primaryColor
//                                   .withOpacity(0.4)
//                               : Theme.of(context).dividerColor,
//                         ),
//                       ),
//                     ),
//                     LayoutBuilder(
//                       builder: (_, constraints) => AnimatedContainer(
//                         duration: const Duration(milliseconds: 500),
//                         height: 48,
//                         width: constraints.maxWidth * (percentage / 100),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8),
//                           color: Theme.of(context)
//                               .primaryColor
//                               .withOpacity(0.2),
//                         ),
//                       ),
//                     ),
//                     Positioned.fill(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: [
//                                 if (isSelected)
//                                   Container(
//                                     width: 8,
//                                     height: 8,
//                                     margin: const EdgeInsets.only(right: 6),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           Theme.of(context).primaryColor,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 Text(
//                                   opt["option_text"] ?? "",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w500,
//                                     color: isSelected
//                                         ? Theme.of(context).primaryColor
//                                         : null,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (votedOptionId != null || isEnded)
//                               Text(
//                                 "$percentage% ($votes)",
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodySmall,
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//
//           const Divider(height: 20),
//
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 isEnded
//                     ? "Poll Ended"
//                     : "${poll["duration"] ?? 0} days left",
//                 style: TextStyle(
//                   color: isEnded ? Colors.red : Colors.grey,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Row(
//                 children: [
//                   if (isLoading)
//                     const SizedBox(
//                       width: 14,
//                       height: 14,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   const SizedBox(width: 6),
//                   Text("$totalVotes votes"),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
