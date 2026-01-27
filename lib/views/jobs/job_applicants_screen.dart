import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/applicant_model.dart';
import '../../services/job_provider.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  late Future<List<Applicant>> _applicantsFuture;

  @override
  void initState() {
    super.initState();
    _applicantsFuture = Provider.of<JobProvider>(context, listen: false)
        .fetchJobApplicants(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Applicants",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.jobTitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Applicant>>(
        future: _applicantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No applicants yet.",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final applicants = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _applicantCard(theme, applicants[index]);
            },
          );
        },
      ),
    );
  }

  Widget _applicantCard(ThemeData theme, Applicant applicant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  applicant.initials,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (applicant.headline.isNotEmpty)
                      Text(
                        applicant.headline,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  applicant.status,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(applicant.email, style: theme.textTheme.bodySmall),
            ],
          ),
          if (applicant.phone.isNotEmpty) ...[
             const SizedBox(height: 8),
             Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(applicant.phone, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (applicant.skills.isNotEmpty)
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: applicant.skills.take(5).map((s) => Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.surface.withValues(alpha: 0.5),
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                 ),
                 child: Text(s, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
               )).toList(),
             ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // View profile or resume (Not implemented fully in this scope)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile view not implemented")));
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("View Profile", style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
