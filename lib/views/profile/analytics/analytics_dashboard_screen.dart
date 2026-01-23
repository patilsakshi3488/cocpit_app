import 'package:flutter/material.dart';
import '../../bottom_navigation.dart';
import 'analytics_stat_card.dart';
import 'analytics_time_range.dart';
import 'trajectory_section.dart';
import 'engagement_section.dart';
import 'funnel_section.dart';
import 'demographics_section.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String selectedRange = "Last 7 Days";

  // Mock data for stat cards based on range
  final Map<String, List<Map<String, dynamic>>> rangeStats = {
    "Last 7 Days": [
      {
        "label": "Profile Views",
        "value": "1,240",
        "trend": "+12.5%",
        "positive": true,
        "icon": Icons.visibility_outlined,
      },
      {
        "label": "Search Appearances",
        "value": "450",
        "trend": "+5.2%",
        "positive": true,
        "icon": Icons.search,
      },
      {
        "label": "Connection Requests",
        "value": "28",
        "trend": "-2.1%",
        "positive": false,
        "icon": Icons.person_add_outlined,
      },
      {
        "label": "Direct Messages",
        "value": "12",
        "trend": "+18.0%",
        "positive": true,
        "icon": Icons.chat_bubble_outline,
      },
    ],
    "Last 30 Days": [
      {
        "label": "Profile Views",
        "value": "4,340",
        "trend": "+15.2%",
        "positive": true,
        "icon": Icons.visibility_outlined,
      },
      {
        "label": "Search Appearances",
        "value": "1,575",
        "trend": "+8.4%",
        "positive": true,
        "icon": Icons.search,
      },
      {
        "label": "Connection Requests",
        "value": "112",
        "trend": "+4.1%",
        "positive": true,
        "icon": Icons.person_add_outlined,
      },
      {
        "label": "Direct Messages",
        "value": "84",
        "trend": "+22.0%",
        "positive": true,
        "icon": Icons.chat_bubble_outline,
      },
    ],
    "Last 90 Days": [
      {
        "label": "Profile Views",
        "value": "12,850",
        "trend": "+24.5%",
        "positive": true,
        "icon": Icons.visibility_outlined,
      },
      {
        "label": "Search Appearances",
        "value": "5,420",
        "trend": "+12.2%",
        "positive": true,
        "icon": Icons.search,
      },
      {
        "label": "Connection Requests",
        "value": "450",
        "trend": "+15.1%",
        "positive": true,
        "icon": Icons.person_add_outlined,
      },
      {
        "label": "Direct Messages",
        "value": "310",
        "trend": "+30.0%",
        "positive": true,
        "icon": Icons.chat_bubble_outline,
      },
    ],
    "All Time": [
      {
        "label": "Profile Views",
        "value": "45.2K",
        "trend": "+140%",
        "positive": true,
        "icon": Icons.visibility_outlined,
      },
      {
        "label": "Search Appearances",
        "value": "18.5K",
        "trend": "+85%",
        "positive": true,
        "icon": Icons.search,
      },
      {
        "label": "Connection Requests",
        "value": "2.1K",
        "trend": "+60%",
        "positive": true,
        "icon": Icons.person_add_outlined,
      },
      {
        "label": "Direct Messages",
        "value": "1.2K",
        "trend": "+95%",
        "positive": true,
        "icon": Icons.chat_bubble_outline,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final textColor =
        theme.textTheme.displaySmall?.color ??
        (isDark ? Colors.white : const Color(0xFF111827));
    final subTextColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white54 : Colors.black54);

    final stats = rangeStats[selectedRange] ?? rangeStats["Last 7 Days"]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Analytics Dashboard",
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Track your professional growth and reach",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            AnalyticsTimeRange(
              selectedRange: selectedRange,
              onRangeSelected: (range) => setState(() => selectedRange = range),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: stats
                    .map(
                      (stat) => AnalyticsStatCard(
                        icon: stat["icon"],
                        label: stat["label"],
                        value: stat["value"],
                        trend: stat["trend"],
                        isPositive: stat["positive"],
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EngagementSection(
                primary: primary,
                textColor: textColor,
                selectedRange: selectedRange,
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TrajectorySection(primary: primary, textColor: textColor),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FunnelSection(
                textColor: textColor,
                subTextColor: subTextColor,
                primary: primary,
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DemographicsSection(
                primary: primary,
                textColor: textColor,
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
