import 'package:flutter/material.dart';
import '../services/feed_service.dart';

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

// ==========================================
// WIDGET: Modern Theme-Aware Implementation
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
        await FeedApi.removePollVote(widget.postId);
      } else {
        print("DEBUG: calling POST API");
        await FeedApi.votePoll(widget.postId, selectedId);
      }

      print("DEBUG: fetching fresh POll");
      final postData = await FeedApi.fetchSinglePost(widget.postId);

      if (mounted && postData != null) {
        if (postData["poll"] != null) {
          print("DEBUG: New Poll Data: ${postData["poll"]}");
          setState(() {
            _data = PollModel.fromJson(postData["poll"]);
          });
          widget.onPollUpdated?.call(postData["poll"]);
        }
      }
    } catch (e) {
      print("DEBUG: Error $e");
      if (mounted) setState(() => _data = previous);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current Theme Data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine background color: subtly distinct from the main surface
    // If we are on a "surface", we might want a slightly different shade.
    // Using surfaceContainer if available or cardColor.
    final backgroundColor = theme.cardColor;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          if (filterShadow(theme))
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Build Options with spacing
          ..._data.options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionRow(context, opt),
            ),
          ),

          // Footer
          if (_data.options.isNotEmpty) _buildFooter(context),
        ],
      ),
    );
  }

  bool filterShadow(ThemeData theme) {
    // Only show shadow if brightness is light, keeps interface clean in dark mode
    return theme.brightness == Brightness.light;
  }

  Widget _buildOptionRow(BuildContext context, PollOption opt) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isSelected = _data.userVote == opt.id;
    final bool showResults = _data.userVote != null || !_data.isActive;

    // Percentage calculation
    final double percent = _data.totalVotes > 0
        ? (opt.voteCount / _data.totalVotes)
        : 0.0;

    final percentString = "${(percent * 100).toStringAsFixed(0)}%";

    // Colors
    // If voted, valid results are shown.
    // If selected, use primary color for highlight.
    // Progress Bar color: Light primary or subtle surface variant
    final progressColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ); // Fallback for visibility

    // Border Color: Primary if selected, otherwise subtle outline
    final borderColor = isSelected ? colorScheme.primary : theme.dividerColor;

    return InkWell(
      onTap: () => _onVotePressed(opt.id),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // 1. Container Frame (Background & Border)
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              // Default background is transparent so progress bar shows up clearly
              // or match the "unfilled" portion
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
          ),

          // 2. Progress Bar (Animated)
          if (showResults)
            LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      height: 48,
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(
                                alpha: 0.2,
                              ) // Highlighted fill
                            : theme.dividerColor.withValues(
                                alpha: 0.3,
                              ), // Neutral fill
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(
                            10,
                          ), // slightly less than container to fit inside border
                          right: value >= 0.98
                              ? const Radius.circular(10)
                              : Radius.zero,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

          // 3. Option Text & Percentage (Overlay)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Option Text
                  Expanded(
                    child: Row(
                      children: [
                        if (isSelected && showResults)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            opt.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Percentage Text
                  if (showResults)
                    Text(
                      percentString,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isEnded = !_data.isActive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Total Votes
        Row(
          children: [
            Text(
              "${_data.totalVotes} votes",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),

        // Time Remaining
        Text(
          isEnded ? "Poll ended" : "${_data.duration}d left",
          style: theme.textTheme.labelMedium?.copyWith(
            color: isEnded
                ? colorScheme.error
                : theme.textTheme.bodySmall?.color,
            fontWeight: isEnded ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
