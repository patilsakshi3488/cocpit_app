  import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/applicant_model.dart';
import '../../services/job_provider.dart';
import '../../services/secure_storage.dart';
import '../profile/profile_screen.dart';
import '../profile/public_profile_screen.dart';

class JobApplicantsView extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  // Callback to go back to dashboard if needed, though Tabs might handle it
  // final VoidCallback? onBack; 

  const JobApplicantsView({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobApplicantsView> createState() => _JobApplicantsViewState();
}

class _JobApplicantsViewState extends State<JobApplicantsView> {
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

    // We return a DefaultTabController directly to be embedded
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   "Applicants",
                   style: theme.textTheme.headlineMedium?.copyWith(
                     fontWeight: FontWeight.bold,
                     color: Colors.white, 
                   ),
                 ),
                 const SizedBox(height: 4),
                 FutureBuilder<List<Applicant>>(
                   future: _applicantsFuture,
                   builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.length : 0;
                      return Text(
                       "$count applicants",
                       style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                     );
                   }
                 ),
               ],
             ),
           ),
           
           // Tabs
           TabBar(
             isScrollable: true,
             indicatorColor: theme.primaryColor,
             labelColor: theme.primaryColor,
             unselectedLabelColor: Colors.grey,
             labelStyle: const TextStyle(fontWeight: FontWeight.bold),
             tabs: const [
               Tab(text: "All"),
               Tab(text: "Shortlisted"),
               Tab(text: "Approved"),
               Tab(text: "Rejected"),
             ],
           ),
           
           const SizedBox(height: 16),
           
           // Search Bar
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0),
             child: TextField(
               decoration: InputDecoration(
                 hintText: "Search applicants...",
                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
                 filled: true,
                 fillColor: theme.colorScheme.surfaceContainer,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: BorderSide.none,
                 ),
                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
               ),
             ),
           ),
           
           const SizedBox(height: 16),

           Expanded(
             child: FutureBuilder<List<Applicant>>(
              future: _applicantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No applicants yet.", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)));
                }

                final applicants = snapshot.data!;
                // Filter logic
                return TabBarView(
                  children: [
                    _buildApplicantList(theme, applicants), // All
                    _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase() == 'shortlisted').toList()), // Shortlisted
                    _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase() == 'approved').toList()), // Approved
                    _buildApplicantList(theme, applicants.where((a) => a.status.toLowerCase() == 'rejected').toList()), // Rejected
                  ],
                );
              },
            ),
           ),
        ],
      ),
    );
  }

  Widget _buildApplicantList(ThemeData theme, List<Applicant> applicants) {
    if (applicants.isEmpty) {
      return Center(child: Text("No applicants in this category", style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: applicants.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _applicantCard(theme, applicants[index]);
      },
    );
  }

  Widget _applicantCard(ThemeData theme, Applicant applicant) {
    bool isShortlisted = applicant.status.toLowerCase() == 'shortlisted';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               CircleAvatar(
                 radius: 24,
                 backgroundColor: Colors.blueAccent,
                 backgroundImage: (applicant.avatarUrl != null && applicant.avatarUrl!.isNotEmpty)
                     ? NetworkImage(applicant.avatarUrl!)
                     : null,
                 child: (applicant.avatarUrl == null || applicant.avatarUrl!.isEmpty)
                     ? Text(applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white))
                     : null,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       applicant.name,
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                       ),
                     ),
                     if (applicant.headline.isNotEmpty)
                        Text(
                         applicant.headline,
                         style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                         maxLines: 1, 
                         overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                           SizedBox(width: 4),
                           // Mock location or date since API doesn't provide it directly in Applicant model yet
                           Text("5/2/2026", style: TextStyle(color: Colors.grey, fontSize: 12)),
                         ],
                       ),
                   ],
                 ),
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: (isShortlisted ? Colors.purpleAccent : Colors.blue).withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   applicant.status.isNotEmpty ? applicant.status : "Applied",
                   style: TextStyle(
                     color: isShortlisted ? Colors.purpleAccent : Colors.blue,
                     fontSize: 10,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: applicant.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("View Profile", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              if (isShortlisted)
                 Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Mock action for Resume button
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Resume for ${applicant.name} clicked!")),
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text("Resume"),
                     style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else 
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                               // Mock Shortlist action
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Shortlisted ${applicant.name}!")),
                              );
                            },
                             style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              foregroundColor: Colors.green,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("Shortlist"),
                          ),
                      ),
                      const SizedBox(width: 8),
                      // Resume button small
                       OutlinedButton(
                        onPressed: () {
                          // Mock action for Resume button
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Resume for ${applicant.name} clicked!")),
                          );
                        },
                         style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          minimumSize: Size(0, 0),
                        ),
                        child: const Icon(Icons.description_outlined, size: 20),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
