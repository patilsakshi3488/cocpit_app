import 'package:flutter/material.dart';

class BackgroundPickerSheet extends StatelessWidget {
  const BackgroundPickerSheet({super.key});

  // Website Palette & Common Gradients
  static const List<Color> _solidColors = [
    Colors.black,
    Colors.white,
    Color(0xFF1A1A1A), // Dark Grey
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF1E88E5), // Blue
    Color(0xFFFFB300), // Amber
    Color(0xFF8E24AA), // Purple
  ];

  static const List<LinearGradient> _gradients = [
    LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ), // Purple -> Blue
    LinearGradient(
      colors: [Color(0xFFf12711), Color(0xFFf5af19)],
    ), // Red -> Orange
    LinearGradient(
      colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
    ), // Cyan -> Blue
    LinearGradient(
      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ), // Green -> Light Green
    LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF434343)],
    ), // Black -> Grey
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Backgrounds",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Solids
                ..._solidColors
                    .map(
                      (c) => GestureDetector(
                        onTap: () => Navigator.pop(context, c),
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                        ),
                      ),
                    )
                    .toList(),

                // Gradients
                ..._gradients
                    .map(
                      (g) => GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          g,
                        ), // Will just pass gradient or first color?
                        // Ideally pass the gradient itself, but return type needs to handle it.
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: g,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
