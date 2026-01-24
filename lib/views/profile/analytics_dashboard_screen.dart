import 'package:flutter/material.dart';
import '../bottom_navigation.dart';
import 'dart:math' as math;

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String selectedRange = "Last 7 Days";
  String selectedRole = "Senior Product Designer";

  final List<String> roles = [
    "Senior Product Designer",
    "Frontend Architect",
    "Marketing Manager",
    "Full Stack Engineer",
  ];

  final Map<String, List<String>> roleSkills = {
    "Senior Product Designer": [
      "UI Design",
      "UX Research",
      "Prototyping",
      "Design Systems",
      "Leadership",
      "Strategy",
    ],
    "Frontend Architect": [
      "React/Next.js",
      "System Architecture",
      "Performance",
      "Testing",
      "DevOps",
      "Mentoring",
    ],
    "Marketing Manager": [
      "SEO/SEM",
      "Content Strategy",
      "Data Analytics",
      "Campaign Management",
      "Public Relations",
      "Brand Design",
    ],
    "Full Stack Engineer": [
      "API Design",
      "Database Mgmt",
      "Frontend Frameworks",
      "Backend Systems",
      "Security",
      "Cloud Arch",
    ],
  };

  final Map<String, List<double>> roleTargetValues = {
    "Senior Product Designer": [0.9, 0.85, 0.8, 0.9, 0.75, 0.8],
    "Frontend Architect": [0.95, 0.9, 0.85, 0.8, 0.75, 0.85],
    "Marketing Manager": [0.85, 0.9, 0.8, 0.85, 0.7, 0.75],
    "Full Stack Engineer": [0.9, 0.85, 0.95, 0.9, 0.8, 0.85],
  };

  final Map<String, List<double>> roleYouValues = {
    "Senior Product Designer": [0.8, 0.7, 0.6, 0.85, 0.5, 0.6],
    "Frontend Architect": [0.85, 0.75, 0.65, 0.7, 0.6, 0.7],
    "Marketing Manager": [0.75, 0.8, 0.7, 0.75, 0.6, 0.65],
    "Full Stack Engineer": [0.8, 0.7, 0.85, 0.75, 0.65, 0.7],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      body: SingleChildScrollView(
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
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Track your professional growth and reach",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Time Range Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildRangeButton("Last 7 Days"),
                  _buildRangeButton("Last 30 Days"),
                  _buildRangeButton("Last 90 Days"),
                  _buildRangeButton("All Time"),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatCard(
                    icon: Icons.visibility_outlined,
                    label: "Profile Views",
                    value: _getStatValue("Profile Views"),
                    trend: "+12.5%",
                    isPositive: true,
                  ),
                  _buildStatCard(
                    icon: Icons.search,
                    label: "Search Appearances",
                    value: _getStatValue("Search Appearances"),
                    trend: "+5.2%",
                    isPositive: true,
                  ),
                  _buildStatCard(
                    icon: Icons.person_add_outlined,
                    label: "Connection Requests",
                    value: "297.5",
                    trend: "-2.1%",
                    isPositive: false,
                  ),
                  _buildStatCard(
                    icon: Icons.chat_bubble_outline,
                    label: "Direct Messages",
                    value: "84",
                    trend: "+18.0%",
                    isPositive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Career Trajectory Section
            _buildTrajectoryCard(),

            const SizedBox(height: 24),

            // Engagement Overview Section
            _buildEngagementCard(),

            const SizedBox(height: 24),

            // Recruiter Funnel Section
            _buildFunnelCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getStatValue(String label) {
    if (selectedRange == "Last 7 Days") {
      return label == "Profile Views" ? "1,240" : "450";
    }
    return label == "Profile Views" ? "4,340" : "1,575";
  }

  Widget _buildRangeButton(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isSelected = selectedRange == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRange = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label.split(" ").join("\n"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 24),
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTrajectoryCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: theme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Career Trajectory & Skill Gap",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Compare your current skills against your dream role.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Dropdown for Role Selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                dropdownColor: theme.scaffoldBackgroundColor,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.iconTheme.color?.withValues(alpha: 0.5),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue!;
                  });
                },
                items: roles.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 280,
              width: 280,
              child: CustomPaint(
                painter: RadarChartPainter(
                  theme: theme,
                  skills: roleSkills[selectedRole]!,
                  targetValues: roleTargetValues[selectedRole]!,
                  youValues: roleYouValues[selectedRole]!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Role Readiness",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(roleYouValues[selectedRole]!.reduce((a, b) => a + b) / roleTargetValues[selectedRole]!.reduce((a, b) => a + b) * 100).toInt()}%",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:
                  roleYouValues[selectedRole]!.reduce((a, b) => a + b) /
                  roleTargetValues[selectedRole]!.reduce((a, b) => a + b),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              color: theme.primaryColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You are on track for this role.",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Engagement Overview",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Profile interactions over time",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegendItem("Interactions", const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _buildLegendItem("Profile Views", theme.primaryColor),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(painter: LineChartPainter(theme: theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildFunnelCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recruiter Funnel",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "From search to conversation",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _funnelStep(
            "SEARCH APPEARANCES",
            "15,750",
            "100%",
            Icons.filter_alt,
            const Color(0xFF3B82F6),
          ),
          _funnelStep(
            "PROFILE CLICKS",
            "4,340",
            "27.5%",
            Icons.mouse,
            theme.primaryColor,
          ),
          _funnelStep(
            "CONNECTED/FOLLOWED",
            "630",
            "14.5%",
            Icons.person_add,
            const Color(0xFF8B5CF6),
          ),
          _funnelStep(
            "MESSAGE/INQUIRY",
            "84",
            "13.3%",
            Icons.chat_bubble,
            const Color(0xFFA855F7),
          ),
        ],
      ),
    );
  }

  Widget _funnelStep(
    String label,
    String value,
    String percentage,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final ThemeData theme;
  final List<String> skills;
  final List<double> targetValues;
  final List<double> youValues;

  RadarChartPainter({
    required this.theme,
    required this.skills,
    required this.targetValues,
    required this.youValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    final gridPaint = Paint()
      ..color = theme.dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw web
    for (var i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final path = Path();
      for (var j = 0; j < 6; j++) {
        final angle = (j * 60) * math.pi / 180;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        gridPaint,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = center.dx + (radius + 25) * math.cos(angle);
      final y = center.dy + (radius + 20) * math.sin(angle);

      textPainter.text = TextSpan(
        text: skills[i],
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Target Area (Green dashed)
    final targetPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final targetPath = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final r = radius * targetValues[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        targetPath.moveTo(x, y);
      } else {
        targetPath.lineTo(x, y);
      }
    }
    targetPath.close();
    canvas.drawPath(targetPath, targetPaint);

    // You Area (Blue filled)
    final youPaint = Paint()
      ..color = theme.primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final youBorderPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final youPath = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final r = radius * youValues[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        youPath.moveTo(x, y);
      } else {
        youPath.lineTo(x, y);
      }
    }
    youPath.close();
    canvas.drawPath(youPath, youPaint);
    canvas.drawPath(youPath, youBorderPaint);

    // Legend
    final legendX = size.width - 60;
    canvas.drawCircle(
      Offset(legendX, 20),
      4,
      Paint()..color = theme.primaryColor.withValues(alpha: 0.5),
    );
    textPainter.text = TextSpan(
      text: "You",
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 10, 14));

    canvas.drawCircle(
      Offset(legendX, 40),
      4,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    textPainter.text = TextSpan(
      text: "Target",
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX + 10, 34));
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return true;
  }
}

class LineChartPainter extends CustomPainter {
  final ThemeData theme;
  LineChartPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.dividerColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height - (size.height / 4 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "${50 * i}",
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(-25, y - 5));
    }

    final dates = ["Dec 8", "Dec 16", "Dec 24", "Jan 1"];
    for (var i = 0; i < dates.length; i++) {
      final x = (size.width / (dates.length - 1)) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: dates[i],
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 10),
      );
    }

    // Profile Views Path (Blue)
    final bluePath = Path();
    final bluePoints = [
      0.5,
      0.65,
      0.6,
      0.75,
      0.72,
      0.6,
      0.8,
      0.65,
      0.9,
      0.75,
      0.85,
      0.78,
      0.88,
      0.92,
    ];
    for (var i = 0; i < bluePoints.length; i++) {
      final x = (size.width / (bluePoints.length - 1)) * i;
      final y = size.height * (1 - bluePoints[i]);
      if (i == 0) {
        bluePath.moveTo(x, y);
      } else {
        bluePath.lineTo(x, y);
      }
    }

    final blueFillPath = Path.from(bluePath);
    blueFillPath.lineTo(size.width, size.height);
    blueFillPath.lineTo(0, size.height);
    blueFillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.primaryColor.withValues(alpha: 0.3),
        theme.primaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(blueFillPath, Paint()..shader = gradient);
    canvas.drawPath(
      bluePath,
      Paint()
        ..color = theme.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Interactions Path (Green)
    final greenPath = Path();
    final greenPoints = [
      0.1,
      0.12,
      0.11,
      0.13,
      0.12,
      0.14,
      0.12,
      0.15,
      0.13,
      0.16,
      0.14,
      0.15,
      0.16,
      0.17,
    ];
    for (var i = 0; i < greenPoints.length; i++) {
      final x = (size.width / (greenPoints.length - 1)) * i;
      final y = size.height * (1 - greenPoints[i]);
      if (i == 0) {
        greenPath.moveTo(x, y);
      } else {
        greenPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      greenPath,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
