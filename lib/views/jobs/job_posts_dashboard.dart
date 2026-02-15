import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class JobPostsDashboard extends StatelessWidget {
  final List<Job> postedJobs;
  final Function(Job) onViewApplicants;
  final Function(Job)? onEdit;
  final Function(Job)? onDelete;

  const JobPostsDashboard({
    super.key,
    required this.postedJobs,
    required this.onViewApplicants,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate Real Stats
    final totalJobs = postedJobs.length;
    final activeJobs = postedJobs.where((j) => j.activelyHiring).length;
    final totalApplicants = postedJobs.fold<int>(0, (sum, j) {
       return sum + j.applicantCount;
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
                return Row(
                  children: stats.map((stat) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  stat['count'],
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: stat['color'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    stat['icon'],
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // Job Posts Section
            Text(
              "Your Job Posts (${postedJobs.length})",
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
              ...postedJobs.map((job) => _dashboardJobCard(context, theme, job)),
          ],
        ),
      ),
    );
  }

  Widget _dashboardJobCard(BuildContext context, ThemeData theme, Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer, // Dark card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Assuming dark theme text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                     job.companyName, 
                     style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call(job);
                  } else if (value == 'delete') {
                    onDelete?.call(job);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Job'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Job', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 8),
                const SizedBox(width: 6),
                Text(
                  "Open", // Dynamic status if available
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
               Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
               SizedBox(width: 4),
               Text(job.location, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
               SizedBox(width: 12),
               Icon(Icons.access_time, size: 14, color: Colors.grey),
               SizedBox(width: 4),
               Text(job.jobType, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   Icon(Icons.people_outline, size: 16, color: Colors.grey),
                   SizedBox(width: 6),
                   Text(
                     "${job.applicantCount} applicants",
                     style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                   ),
                 ],
               ),
               Text(
                 job.postedTimeAgo,
                 style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
               ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onViewApplicants(job),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "View Applicants",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
