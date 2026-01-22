import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int connectionCount;

  const ProfileStats({
    super.key,
     required this.connectionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            context,
            connectionCount.toString()+"+"??"500+",
            "connections",
          ),
          Container(height: 40, width: 1, color: theme.dividerColor),
          _statItem(
            context,
            // connectionCount.toString()+"+"??"500+",
            "1234+",
            "Profile Views",
          ),
          Container(height: 40, width: 1, color: theme.dividerColor),
          _statItem(
            context,
            // connectionCount.toString()+"+"??"500+",
            "87+",
            "Posts",
          ),


        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
