  import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/applicant_model.dart';
import '../../services/job_provider.dart';
import '../../services/secure_storage.dart';
import '../profile/profile_screen.dart';
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

        final currentUserJson = await AppSecureStorage.getUser();
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: applicant.id,
            ),
          ),
        );
        debugPrint("🔍 Applicant ID: ${applicant.id}");
      },

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────── HEADER ─────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    applicant.status,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ───────── CONTACT ─────────
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(applicant.email, style: theme.textTheme.bodySmall),
              ],
            ),

            if (applicant.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text(applicant.phone, style: theme.textTheme.bodySmall),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ───────── SKILLS ─────────
            if (applicant.skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: applicant.skills.take(5).map((skill) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                      theme.colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // ───────── ACTION ─────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        userId: applicant.id, // ✅ USER ID
                      ),
                    ),
                  );
                },

                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                Text("View Profile", style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }


// Widget _applicantCard(ThemeData theme, Applicant applicant) {
  //   // Widget _postHeader(Map<String, dynamic> post, ThemeData theme) {
  //     return GestureDetector(
  //       onTap: () async {
  //         if (applicant.id != null) {
  //           final currentUserJson = await AppSecureStorage.getUser();
  //           if (currentUserJson != null) {
  //             final currentUser = jsonDecode(currentUserJson);
  //             final currentUserId =
  //                 currentUser['id']?.toString() ??
  //                     currentUser['user_id']?.toString();
  //             final authorId = applicant.id.toString();
  //
  //             debugPrint("🔍 CHECK: User $currentUserId vs Author $authorId");
  //
  //             if (currentUserId == authorId) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => const ProfileScreen()),
  //               );
  //               return;
  //             }
  //           }
  //
  //           if (mounted) {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) =>
  //                     PublicProfileScreen(userId: applicant.id.toString()),
  //               ),
  //             );
  //           }
  //         }
  //       },
  //
  //       child:padding: const EdgeInsets.all(16),
  //   decoration: BoxDecoration(
  //   color: theme.cardColor,
  //   borderRadius: BorderRadius.circular(16),
  //   border: Border.all(color: theme.dividerColor),
  //   ),
  //   child: Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //   Row(
  //   children: [
  //   CircleAvatar(
  //   radius: 24,
  //   backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
  //   child: Text(
  //   applicant.initials,
  //   style: TextStyle(
  //   color: theme.primaryColor,
  //   fontWeight: FontWeight.bold,
  //   ),
  //   ),
  //   ),
  //   const SizedBox(width: 16),
  //   Expanded(
  //   child: Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //   Text(
  //   applicant.name,
  //   style: theme.textTheme.titleMedium?.copyWith(
  //   fontWeight: FontWeight.bold,
  //   ),
  //   ),
  //   if (applicant.headline.isNotEmpty)
  //   Text(
  //   applicant.headline,
  //   style: theme.textTheme.bodySmall,
  //   maxLines: 1,
  //   overflow: TextOverflow.ellipsis,
  //   ),
  //   ],
  //   ),
  //   ),
  //   Container(
  //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //   decoration: BoxDecoration(
  //   color: theme.dividerColor.withValues(alpha: 0.2),
  //   borderRadius: BorderRadius.circular(8),
  //   ),
  //   child: Text(
  //   applicant.status,
  //   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
  //   ),
  //   ),
  //   ],
  //   ),
  //   const SizedBox(height: 16),
  //   Row(
  //   children: [
  //   Icon(Icons.email_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
  //   const SizedBox(width: 8),
  //   Text(applicant.email, style: theme.textTheme.bodySmall),
  //   ],
  //   ),
  //   if (applicant.phone.isNotEmpty) ...[
  //   const SizedBox(height: 8),
  //   Row(
  //   children: [
  //   Icon(Icons.phone_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
  //   const SizedBox(width: 8),
  //   Text(applicant.phone, style: theme.textTheme.bodySmall),
  //   ],
  //   ),
  //   ],
  //   const SizedBox(height: 16),
  //   if (applicant.skills.isNotEmpty)
  //   Wrap(
  //   spacing: 8,
  //   runSpacing: 8,
  //   children: applicant.skills.take(5).map((s) => Container(
  //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //   decoration: BoxDecoration(
  //   color: theme.colorScheme.surface.withValues(alpha: 0.5),
  //   borderRadius: BorderRadius.circular(4),
  //   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
  //   ),
  //   child: Text(s, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
  //   )).toList(),
  //   ),
  //
  //   const SizedBox(height: 16),
  //   SizedBox(
  //   width: double.infinity,
  //   child: OutlinedButton(
  //   onPressed: () {
  //   // onPressed: () => _showAnalyticsModal(context, job),
  //
  //   // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile view not implemented")));
  //   },
  //   style: OutlinedButton.styleFrom(
  //   side: BorderSide(color: theme.dividerColor),
  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //   ),
  //   child: Text("View Profile", style: theme.textTheme.bodyMedium),
  //   ),
  //   ),
  //   ],
  //   ),
    // }
        // child: Padding(
        //   padding: const EdgeInsets.all(12),
        //   child: Row(
        //     children: [
        //       CircleAvatar(
        //         radius: 22,
        //         backgroundImage:applicant.id != null
        //             ? NetworkImage(applicant.initials)
        //             : null,
        //         child:applicant.initials == null
        //             ? Text(applicant.name?[0] ?? "?")
        //             : null,
        //       ),
        //       const SizedBox(width: 10),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //           applicant.name ?? "",
        //               style: theme.textTheme.titleSmall?.copyWith(
        //                 fontWeight: FontWeight.bold,
        //               ),
        //             ),
        //             // Text(
        //             //   post["category_name"] ?? "",
        //             //   style: theme.textTheme.bodySmall,
        //             // ),
        //           ],
        //         ),
        //       ),
        //       Icon(Icons.more_vert, color: theme.iconTheme.color),
        //     ],
        //   ),
        // ),
    //   );
    // }


    // return Container(
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: theme.cardColor,
    //     borderRadius: BorderRadius.circular(16),
    //     border: Border.all(color: theme.dividerColor),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         children: [
    //           CircleAvatar(
    //             radius: 24,
    //             backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
    //             child: Text(
    //               applicant.initials,
    //               style: TextStyle(
    //                 color: theme.primaryColor,
    //                 fontWeight: FontWeight.bold,
    //               ),
    //             ),
    //           ),
    //           const SizedBox(width: 16),
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
    //           Container(
    //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    //             decoration: BoxDecoration(
    //               color: theme.dividerColor.withValues(alpha: 0.2),
    //               borderRadius: BorderRadius.circular(8),
    //             ),
    //             child: Text(
    //               applicant.status,
    //               style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
    //             ),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 16),
    //       Row(
    //         children: [
    //           Icon(Icons.email_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
    //           const SizedBox(width: 8),
    //           Text(applicant.email, style: theme.textTheme.bodySmall),
    //         ],
    //       ),
    //       if (applicant.phone.isNotEmpty) ...[
    //          const SizedBox(height: 8),
    //          Row(
    //           children: [
    //             Icon(Icons.phone_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
    //             const SizedBox(width: 8),
    //             Text(applicant.phone, style: theme.textTheme.bodySmall),
    //           ],
    //         ),
    //       ],
    //       const SizedBox(height: 16),
    //       if (applicant.skills.isNotEmpty)
    //          Wrap(
    //            spacing: 8,
    //            runSpacing: 8,
    //            children: applicant.skills.take(5).map((s) => Container(
    //              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //              decoration: BoxDecoration(
    //                color: theme.colorScheme.surface.withValues(alpha: 0.5),
    //                borderRadius: BorderRadius.circular(4),
    //                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
    //              ),
    //              child: Text(s, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color)),
    //            )).toList(),
    //          ),
    //
    //       const SizedBox(height: 16),
    //       SizedBox(
    //         width: double.infinity,
    //         child: OutlinedButton(
    //           onPressed: () {
    //             // onPressed: () => _showAnalyticsModal(context, job),
    //
    //             // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile view not implemented")));
    //           },
    //           style: OutlinedButton.styleFrom(
    //             side: BorderSide(color: theme.dividerColor),
    //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //           ),
    //           child: Text("View Profile", style: theme.textTheme.bodyMedium),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  // }
}
