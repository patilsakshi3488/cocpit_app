
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/applicant_model.dart';
import '../../services/job_provider.dart';
import '../profile/public_profile_screen.dart';

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
    return GestureDetector(


      onTap: () async {
        if (applicant.id.isEmpty) return;

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: applicant.id,
            ),
          ),
        );
        debugPrint("ðŸ” Applicant ID: ${applicant.id}");
      },

      // child: Container(
      //   padding: const EdgeInsets.all(16),
      //   decoration: BoxDecoration(
      //     color: theme.cardColor,
      //     borderRadius: BorderRadius.circular(16),
      //     border: Border.all(color: theme.dividerColor),
      //   ),
      //
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // â”€â”€â”€â”€â”€â”€â”€â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€
      //       Row(
      //         children: [
      //           CircleAvatar(
      //             radius: 24,
      //             backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
      //             backgroundImage: (applicant.avatarUrl != null &&
      //                 applicant.avatarUrl!.isNotEmpty)
      //                 ? NetworkImage(applicant.avatarUrl!)
      //                 : null,
      //             child: (applicant.avatarUrl == null ||
      //                 applicant.avatarUrl!.isEmpty)
      //                 ? Text(
      //               applicant.initials,
      //               style: TextStyle(
      //                 color: theme.primaryColor,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             )
      //                 : null,
      //           ),
      //
      //           const SizedBox(width: 16),
      //
      //           Expanded(
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 Text(
      //                   applicant.name,
      //                   style: theme.textTheme.titleMedium?.copyWith(
      //                     fontWeight: FontWeight.bold,
      //                   ),
      //                 ),
      //                 if (applicant.headline.isNotEmpty)
      //                   Text(
      //                     applicant.headline,
      //                     style: theme.textTheme.bodySmall,
      //                     maxLines: 1,
      //                     overflow: TextOverflow.ellipsis,
      //                   ),
      //               ],
      //             ),
      //           ),
      //
      //           Container(
      //             padding:
      //             const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      //             decoration: BoxDecoration(
      //               color: theme.dividerColor.withValues(alpha: 0.2),
      //               borderRadius: BorderRadius.circular(8),
      //             ),
      //             child: Text(
      //               applicant.status,
      //               style: theme.textTheme.bodySmall
      //                   ?.copyWith(fontWeight: FontWeight.bold),
      //             ),
      //           ),
      //         ],
      //       ),
      //
      //       const SizedBox(height: 16),
      //
      //       // â”€â”€â”€â”€â”€â”€â”€â”€â”€ CONTACT â”€â”€â”€â”€â”€â”€â”€â”€â”€
      //       Row(
      //         children: [
      //           Icon(Icons.email_outlined,
      //               size: 16,
      //               color: theme.textTheme.bodySmall?.color),
      //           const SizedBox(width: 8),
      //           Text(applicant.email, style: theme.textTheme.bodySmall),
      //         ],
      //       ),
      //
      //       if (applicant.phone.isNotEmpty) ...[
      //         const SizedBox(height: 8),
      //         Row(
      //           children: [
      //             Icon(Icons.phone_outlined,
      //                 size: 16,
      //                 color: theme.textTheme.bodySmall?.color),
      //             const SizedBox(width: 8),
      //             Text(applicant.phone, style: theme.textTheme.bodySmall),
      //           ],
      //         ),
      //       ],
      //
      //       const SizedBox(height: 16),
      //
      //       // â”€â”€â”€â”€â”€â”€â”€â”€â”€ SKILLS â”€â”€â”€â”€â”€â”€â”€â”€â”€
      //       if (applicant.skills.isNotEmpty)
      //         Wrap(
      //           spacing: 8,
      //           runSpacing: 8,
      //           children: applicant.skills.take(5).map((skill) {
      //             return Container(
      //               padding:
      //               const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //               decoration: BoxDecoration(
      //                 color:
      //                 theme.colorScheme.surface.withValues(alpha: 0.5),
      //                 borderRadius: BorderRadius.circular(6),
      //                 border: Border.all(
      //                   color: theme.dividerColor.withValues(alpha: 0.5),
      //                 ),
      //               ),
      //               child: Text(
      //                 skill,
      //                 style: theme.textTheme.bodySmall
      //                     ?.copyWith(fontSize: 10),
      //               ),
      //             );
      //           }).toList(),
      //         ),
      //
      //       const SizedBox(height: 16),
      //
      //       // â”€â”€â”€â”€â”€â”€â”€â”€â”€ ACTION â”€â”€â”€â”€â”€â”€â”€â”€â”€
      //       SizedBox(
      //         width: double.infinity,
      //         child: OutlinedButton(
      //           onPressed: () {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (_) => PublicProfileScreen(
      //                   userId: applicant.id, // âœ… USER ID
      //                 ),
      //               ),
      //             );
      //           },
      //
      //           style: OutlinedButton.styleFrom(
      //             backgroundColor: theme.primaryColor,
      //             side: BorderSide(color: theme.dividerColor),
      //             shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(8),
      //
      //             ),
      //           ),
      //           child:
      //           Text("View Profile", style: theme.textTheme.bodyMedium),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),

      child: Container(
        padding: const EdgeInsets.all(20), // Increased for better breathing room
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24), // Smoother corners
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€â”€â”€â”€â”€â”€â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26, // Slightly larger for better focus
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: (applicant.avatarUrl != null &&
                        applicant.avatarUrl!.isNotEmpty)
                        ? NetworkImage(applicant.avatarUrl!)
                        : null,
                    child: (applicant.avatarUrl == null ||
                        applicant.avatarUrl!.isEmpty)
                        ? Text(
                      applicant.initials,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (applicant.headline.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            applicant.headline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1), // Themed highlight
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    applicant.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor, // Matching theme primary
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // â”€â”€â”€â”€â”€â”€â”€â”€â”€ CONTACT â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 16,
                          color: theme.primaryColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Text(applicant.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (applicant.phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 16,
                            color: theme.primaryColor.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Text(applicant.phone, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // â”€â”€â”€â”€â”€â”€â”€â”€â”€ SKILLS â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (applicant.skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: applicant.skills.take(5).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: Text(
                      skill,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // â”€â”€â”€â”€â”€â”€â”€â”€â”€ ACTION â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        userId: applicant.id,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.primaryColor, // Solid themed fill
                  side: BorderSide.none,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                Text(
                  "View Profile",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary, // Specifically sets text to white/onPrimary
                    fontWeight: FontWeight.bold,        // Makes it more 'Action' oriented
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

