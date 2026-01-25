import 'package:flutter/material.dart';

class JobPostsDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> postedJobs;
  const JobPostsDashboard({super.key, required this.postedJobs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate Real Stats
    final totalJobs = postedJobs.length;
    final activeJobs = postedJobs.where((j) => j['isHiring'] == true).length;
    final totalApplicants = postedJobs.fold<int>(0, (sum, j) {
       // Extract "0" from "0 applicants applied"
       final str = j['applicants'] as String? ?? "0";
       final count = int.tryParse(str.split(' ')[0]) ?? 0;
       return sum + count;
    });

    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Total Jobs Posted',
        'count': totalJobs.toString(),
        'icon': Icons.work_outline,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Active Jobs',
        'count': activeJobs.toString(),
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.greenAccent,
      },
      {
        'title': 'Total Applicants',
        'count': totalApplicants.toString(),
        'icon': Icons.people_outline,
        'color': Colors.pinkAccent,
      },
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Job Posts Dashboard",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your job postings and review applicants",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: stats.map((stat) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat['title'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                stat['count'],
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: stat['color'].withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              stat['icon'],
                              color: stat['color'],
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // Job Posts Section
            Text(
              "Your Job Posts ($totalJobs)",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (postedJobs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    "No job posts found.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              )
            else
              ...postedJobs.map((job) => _dashboardJobCard(theme, job)),
          ],
        ),
      ),
    );
  }

  Widget _dashboardJobCard(ThemeData theme, Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job['title'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (job['isHiring'] == true ? Colors.green : Colors.grey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job['isHiring'] == true ? "Active" : "Closed",
                  style: TextStyle(
                    color: job['isHiring'] == true ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${job['applicants']} • Posted ${job['time']}",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
