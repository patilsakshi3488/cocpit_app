
import 'package:flutter/material.dart';

class JobDashboardSample extends StatefulWidget {
  const JobDashboardSample({super.key});

  @override
  State<JobDashboardSample> createState() => _JobDashboardSampleState();
}

class _JobDashboardSampleState extends State<JobDashboardSample> {
  // Hardcoded data to match the screenshot
  final List<Map<String, dynamic>> _jobs = [
    {
      'initials': 'S',
      'title': 's.devloper',
      'company': 'Safra',
      'location': 'dubai',
      'type': 'Full-time',
      'salary': '\$12k - \$16k',
      'timeAgo': '19h ago',
      'applicants': '2 applicants applied',
      'isHiring': true,
      'isApplied': true,
      'color': const Color(0xFF2C2C3E), // Dark card bg
    },
    {
      'initials': 'C',
      'title': 'c',
      'company': 'c',
      'location': 'C',
      'type': 'Contract',
      'salary': '\$122k - \$1333k',
      'timeAgo': '22h ago',
      'applicants': '1 applicants applied',
      'isHiring': true,
      'isApplied': false,
      'color': const Color(0xFF2C2C3E),
    },
    {
      'initials': 'B',
      'title': 'B',
      'company': 'B',
      'location': 'B',
      'type': 'Contract',
      'salary': '\$1222k - \$1222k',
      'timeAgo': '23h ago',
      'applicants': '1 applicants applied',
      'isHiring': true,
      'isApplied': false,
      'color': const Color(0xFF2C2C3E),
    },
     {
      'initials': 'A',
      'title': 'A',
      'company': 'A',
      'location': 'A',
      'type': 'Full-time',
      'salary': '\$10k - \$20k',
      'timeAgo': '1d ago',
      'applicants': '5 applicants applied',
      'isHiring': true,
      'isApplied': false,
      'color': const Color(0xFF2C2C3E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Assuming a dark theme base from the screenshot, but adapting to current context theme
    final theme = Theme.of(context);
    // Determine if we should force dark mode colors or use theme.
    // The screenshot is dark mode. Let's try to stick to the design colors where possible while using theme structure.
    final bgColor = const Color(0xFF1E1E2C); // Background from screenshot
    final cardColor = const Color(0xFF252538); // Card background
    final textColor = Colors.white;
    final secondaryTextColor = Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Header "Jobs"
              Text(
                "Jobs",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar + Add Button
              Row(
                children: [
                   Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C3E),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Search jobs...",
                          hintStyle: TextStyle(color: secondaryTextColor),
                          prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A75FF), // Blue button color
                      shape: BoxShape.circle,
                    ),
                     child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement Post Job action
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab("View Jobs", isActive: true),
                    _buildTab("My Jobs"),
                    _buildTab("Offers"),
                    _buildTab("Job Posts Dashboard"), // Keeping the full name as in screenshot it cuts off but "Job Posts Dashbo..."
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Count & Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "10 jobs found",
                    style: TextStyle(color: secondaryTextColor, fontSize: 16),
                  ),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: const Color(0xFF2C2C3E),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.filter_list, color: secondaryTextColor, size: 18),
                         const SizedBox(width: 6),
                         Text("Filters", style: TextStyle(color: secondaryTextColor)),
                       ],
                     ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Job List
              Expanded(
                child: ListView.separated(
                  itemCount: _jobs.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    return _buildJobCard(job, cardColor, textColor, secondaryTextColor);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Align + button at bottom center if needed, but screenshot shows it in search bar row. 
      // Wait, the screenshot shows a + button at bottom center navigation bar? 
      // Ah, Image 1 (left) shows + button next to Search Bar. 
      // Image 2 (right - actual mockup) shows + button in bottom nav/FAB.
      // User request: "below + post a job button should be above like same as a that image" -> implies moving it to top.
      // And "search bar make list 1st ss" -> implies matching the left screenshot.
    );
  }

  Widget _buildTab(String text, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFF2C2C3E), // Purple/Blue for active, Dark for inactive
        borderRadius: BorderRadius.circular(25),
        gradient: isActive ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, Color cardBg, Color textColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               CircleAvatar(
                 radius: 20,
                 backgroundColor: const Color(0xFF2C2C3E), // Somewhat lighter
                 child: Text(job['initials'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Text(
                           job['title'],
                           style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         const SizedBox(width: 8),
                         if (job['isHiring'])
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.green.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: const Text(
                               "Hiring",
                               style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                             ),
                           ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(
                       "${job['company']} • ${job['location']}",
                       style: TextStyle(color: secondaryColor, fontSize: 13),
                     ),
                   ],
                 ),
               ),
               Icon(Icons.bookmark_border, color: secondaryColor),
             ],
           ),
           const SizedBox(height: 16),
           
           // Details Row
           Row(
             children: [
               Icon(Icons.work_outline, size: 16, color: secondaryColor),
               const SizedBox(width: 4),
               Text(job['type'], style: TextStyle(color: secondaryColor, fontSize: 13)),
               const SizedBox(width: 16),
               Text(job['salary'], style: TextStyle(color: secondaryColor, fontSize: 13)), // Using text color same as icon implies secondary? Screenshot shows white salary.
             ],
           ),
           const SizedBox(height: 12),
           
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Row(
                 children: [
                   Icon(Icons.access_time, size: 16, color: secondaryColor),
                   const SizedBox(width: 4),
                   Text(job['timeAgo'], style: TextStyle(color: secondaryColor, fontSize: 13)),
                 ],
               ),
                if (job['isApplied'] == true)
                 Row(
                   children: [
                     const Text("Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const SizedBox(width: 12),
                     const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                     const SizedBox(width: 4),
                     const Text("Applied", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ],
                 )
                else
                  const Text("Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             ],
           ),
            const SizedBox(height: 8),
            Text(job['applicants'], style: TextStyle(color: const Color(0xFF5A75FF), fontSize: 12)),
        ],
      ),
    );
  }
}
