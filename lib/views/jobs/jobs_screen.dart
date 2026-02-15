import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bottom_navigation.dart';
import '../../widgets/app_top_bar.dart';
import '../../models/job_model.dart';
import '../../services/job_provider.dart';
import '../../services/secure_storage.dart';
import '../profile/profile_models.dart';
import 'job_details_screen.dart';
import 'job_applicants_screen.dart';
import 'job_posts_dashboard.dart';
import 'post_job_modal.dart';
import '../../services/job_service.dart';
import 'task_recording_screen.dart';
import 'widgets/task_submission_modal.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int mainTab = 0; // 0: View Jobs, 1: My Jobs, 2: Offers, 3: Dashboard
  int subTab = 0; // 0: Applied, 1: In Past, 2: Saved, 3: Hiring (Posted)
  bool _isAdmin = false;

  Map<String, dynamic> _currentFilters = {};
  Job? _selectedJobForApplicants;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkAdminRole();
    });
  }

  Future<void> _checkAdminRole() async {
    try {
      final currentUserJson = await AppSecureStorage.getUser();

      if (currentUserJson != null) {
        final Map<String, dynamic> user = jsonDecode(currentUserJson);
        debugPrint("user : $user");

        final accountType =
            user['profile']?['accountType'] ?? user['account_type'];
        debugPrint("account type of user : " + accountType);
        if (accountType != null &&
            accountType.toString().toLowerCase() == 'admin') {
          setState(() {
            _isAdmin = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking admin role: $e");
    }
  }

  void _loadData() {
    final provider = Provider.of<JobProvider>(context, listen: false);
    if (mainTab == 0) {
      provider.fetchJobs();
    } else if (mainTab == 1) {
      if (subTab == 0 || subTab == 1) {
         // 0: Applied, 1: In Past
         String? status;
         if (subTab == 0) status = "applied";
         if (subTab == 1) status = "in past";
         provider.fetchMyApplications(status: status);
      } else if (subTab == 2) {
        provider.fetchMySavedJobs();
      } else if (subTab == 3) {
        provider.fetchMyPostedJobs();
      }
    } else if (mainTab == 2) {
    } else if (mainTab == 2) {
      provider.fetchJobOffers();
    } else if (mainTab == 3) {
      provider.fetchMyPostedJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<JobProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppTopBar(
        searchType: SearchType.jobs,
        onSearchTap: () => _showSearchModal(context),
        onFilterTap: () => _showFilterModal(context),
        onPostJobTap: () => _showPostJobModal(context),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Post Job button moved to FAB
            SliverToBoxAdapter(child: _tabs(theme, provider)),
            _contentArea(theme, provider),
          ],
        ),
      ),
    );
  }

  Widget _postJobHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          debugPrint("POST JOB HEADER TAPPED");
          _showPostJobModal(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.primaryColor,
                child: Icon(
                  Icons.add,
                  color: theme.colorScheme.onPrimary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Post a job",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      "Find the right talent for your team",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs(ThemeData theme, JobProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabPill(theme, "View Jobs", 0),
                _tabPill(theme, "My Jobs", 1),
                _tabPill(
                  theme,
                  "Offers",
                  2,
                  badge: provider.jobOffers.isNotEmpty
                      ? "${provider.jobOffers.length}"
                      : null,
                ),
                _tabPill(theme, "DASHBOARD (TEST)", 3), // Tracer Bullet
              ],
            ),
          ),
          if (mainTab == 1) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subTabPill(theme, "Applied", 0),
                  _subTabPill(theme, "In Past", 1),
                  _subTabPill(theme, "Saved", 2),
                  _subTabPill(theme, "Hiring", 3),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabPill(ThemeData theme, String text, int index, {String? badge}) {
    bool active = mainTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          mainTab = index;
          _selectedJobForApplicants = null;
        });
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? theme.primaryColor
              : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: active ? null : Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: active
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                      : theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subTabPill(ThemeData theme, String text, int index) {
    bool active = subTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => subTab = index);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? theme.primaryColor
              : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: theme.dividerColor),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: active
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _contentArea(ThemeData theme, JobProvider provider) {
    List<Job> list = [];
    bool isHiringView = false;
    bool isLoading = false;
    String emptyMessage = "No jobs found.";

    if (mainTab == 0) {
      list = provider.allJobs;
      isLoading = provider.isLoadingJobs;
      emptyMessage = "No jobs found matching your criteria.";
    } else if (mainTab == 1) {
      if (subTab == 0 || subTab == 1) {
        list = provider.myApplications;
        isLoading = provider.isLoadingMyApps;
        emptyMessage = "No applications found.";
      } else if (subTab == 2) {
        list = provider.mySavedJobs;
        isLoading = provider.isLoadingSaved;
        emptyMessage = "No saved jobs.";
      } else if (subTab == 3) {
        list = provider.myPostedJobs;
        isLoading = provider.isLoadingPosted;
        isHiringView = true;
        emptyMessage = "You haven't posted any jobs yet.";
      }
    } else if (mainTab == 2) {
      list = provider.jobOffers;
      isLoading = provider.isLoadingOffers;
      emptyMessage = "No job offers at the moment.";
    } else if (mainTab == 3) {
      if (_selectedJobForApplicants != null) {
        return SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8, // Give it substantial height
            child: JobApplicantsView(
              jobId: _selectedJobForApplicants!.id,
              jobTitle: _selectedJobForApplicants!.title,
            ),
          ),
        );
      }
      return JobPostsDashboard(
        postedJobs: provider.myPostedJobs,
        onViewApplicants: (job) {
          setState(() {
            _selectedJobForApplicants = job;
          });
        },
        onEdit: _editJob,
        onDelete: _deleteJob,
      );
    }

    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (list.isEmpty) {
      return SliverToBoxAdapter(child: _emptyState(theme, emptyMessage));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _jobCard(
            theme,
            list[index],
            provider,
            isHiringView: isHiringView,
          ),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (mainTab == 0) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Provider.of<JobProvider>(
                    context,
                    listen: false,
                  ).fetchJobs(); // Fetch all
                },
                child: Text(
                  "Clear filters",
                  style: TextStyle(color: theme.primaryColor, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _jobCard(
    ThemeData theme,
    Job job,
    JobProvider provider, {
    bool isHiringView = false,
  }) {
    bool isMyJob = mainTab == 1;
    bool isSaved = job.isSaved;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  job.initials,
                  style: theme.textTheme.headlineMedium?.copyWith(
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
                      job.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isMyJob &&
                        job.applicationStatus != null &&
                        !isHiringView) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(job.applicationStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          job.applicationStatus!,
                          style: TextStyle(
                            color: _getStatusColor(job.applicationStatus),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Text(job.companyName, style: theme.textTheme.bodyLarge),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.circle,
                          size: 4,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job.location,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (job.activelyHiring) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              // color: theme.primaryColor,
                              // shape: BoxShape.circle,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Hiring",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved
                      ? theme.colorScheme.secondary
                      : theme.textTheme.bodySmall?.color,
                ),
                onPressed: () async {
                  try {
                    await provider.toggleSaveJob(job.id, isSaved);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow(theme, job),
          const SizedBox(height: 12),
          
          if (isMyJob && !isHiringView) ...[
             const SizedBox(height: 16),
             _buildApplicationTimeline(theme, job),
             
             // Show task if assigned (flag is true OR task details exist OR status indicates assignment)
             if ((job.taskAssigned || job.taskType != null || ['Task Assignment', 'Task Assigned'].contains(job.applicationStatus)) && job.submissionDate == null) ...[
               const SizedBox(height: 16),
               _buildActionRequiredCard(theme, job),
             ],
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: theme.dividerColor, height: 1),
          ),
          _footerInfo(theme, job),
          const SizedBox(height: 24),
          if (isHiringView)
            _hiringActionButtons(theme, job)
          else
            _actionButtons(theme, job),
          // Timeline view needs more data from API, hiding for now or simplify
        ],
      ),
    );
  }
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.blue;
    final s = status.toLowerCase();
    if (s == 'applied') return Colors.blue;
    if (s == 'viewed' || s.contains('review')) return Colors.orange;
    if (s == 'shortlisted') return Colors.green;
    if (s == 'rejected') return Colors.red;
    if (s.contains('task')) return Colors.purpleAccent;
    return Colors.blue;
  }
  
  Widget _buildApplicationTimeline(ThemeData theme, Job job) {
    // Calculate task active state explicitly
    bool isTaskActive = job.taskAssigned; 
    if (job.taskType != null && job.taskType!.isNotEmpty) {
      isTaskActive = true;
    }
    if (['Task Assignment', 'Task Assigned'].contains(job.applicationStatus)) {
      isTaskActive = true;
    }

    final steps = [
      {'label': 'Application Sent', 'active': true},
      {'label': 'Application Viewed', 'active': job.applicationStatus != 'Applied'},
      {'label': 'Shortlisted', 'active': ['Shortlisted', 'Task Assignment', 'Interview'].contains(job.applicationStatus)},
      {'label': 'Task Assignment', 'active': isTaskActive},
    ];
    
    return Row(
      children: steps.asMap().entries.map((entry) {
        int idx = entry.key;
        var step = entry.value;
        bool isActive = step['active'] as bool;
        bool isLast = idx == steps.length - 1;
        
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                   Expanded(child: idx == 0 ? const SizedBox() : Container(height: 2, color: isActive ? Colors.green : theme.dividerColor)),
                   Icon(
                     isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                     color: isActive ? Colors.green : Colors.grey,
                     size: 20,
                   ),
                   Expanded(child: isLast ? const SizedBox() : Container(height: 2, color: isActive ? (steps[idx+1]['active'] as bool ? Colors.green : theme.dividerColor) : theme.dividerColor)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                step['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildActionRequiredCard(ThemeData theme, Job job) {
    // Fallback to "Video Task" if taskType is missing but status says assigned
    final String effectiveTaskType = job.taskType ?? "Video Task"; 
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1B1B), // Dark orange/red background for alert
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: const BoxDecoration(
               color: Colors.orange,
               shape: BoxShape.circle 
             ),
             child: const Icon(Icons.bolt, color: Colors.white, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   "Action Required",
                   style: TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 14,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   "The recruiter has requested a $effectiveTaskType.",
                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
                 ),
                 if (job.taskInstruction != null) ...[
                    const SizedBox(height: 4),
                    Text(
                       job.taskInstruction!,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                 ]
               ],
             ),
           ),
           ElevatedButton(
             onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => TaskSubmissionModal(
                    taskType: effectiveTaskType,
                    instruction: job.taskInstruction ?? "Please complete the task.",
                    onSubmit: (mode, data) async {
                       try {
                         final provider = Provider.of<JobProvider>(context, listen: false);
                         if (job.applicationId == null) throw Exception("Application ID missing");
                         
                         await provider.submitTask(
                           applicationId: job.applicationId!,
                           file: File(data),
                         );
                         
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Task Submitted Successfully!")),
                           );
                           // Refresh job data
                           provider.fetchJobDetails(job.id);
                         }
                       } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Submission failed: $e")),
                           );
                         }
                       }
                    },
                  ),
                );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.orange,
               foregroundColor: Colors.white,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
             ),
             child: const Text("Start Recording"), // Or "View Task"
           ),
        ],
      ),
    );
  }


  Widget _infoRow(ThemeData theme, Job job) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(theme, Icons.work_outline, job.jobType),
        _pill(theme, Icons.attach_money, job.salaryRange),
        _pill(theme, Icons.access_time, job.postedTimeAgo),
      ],
    );
  }

  Widget _pill(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.textTheme.bodySmall?.color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _footerInfo(ThemeData theme, Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
            const SizedBox(width: 10),
            Text(
              "Active",
              style: theme.textTheme.bodyMedium,
            ), // Or use job status if available
          ],
        ),
        // const SizedBox(height: 8),
        // Text("25 applicants", style: theme.textTheme.bodySmall), // Need this from API
      ],
    );
  }

  Widget _actionButtons(ThemeData theme, Job job) {
    if (job.hasApplied) {
      return Row(
        children: [
          Expanded(child: _detailsBtn(theme, job)),
          const SizedBox(width: 16),
          _appliedStatusBtn(theme),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _detailsBtn(theme, job)),
        const SizedBox(width: 16),
        Expanded(child: _quickApplyBtn(theme, job)),
      ],
    );
  }

  Widget _hiringActionButtons(ThemeData theme, Job job) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showJobDetails(context, job),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "Details",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showAnalyticsModal(context, job),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              "Applicants",
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsBtn(ThemeData theme, Job job, {bool fullWidth = false}) {
    var btn = OutlinedButton(
      onPressed: () => _showJobDetails(context, job),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: theme.dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        "Details",
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  Widget _appliedStatusBtn(ThemeData theme) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "Applied",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickApplyBtn(ThemeData theme, Job job) {
    return ElevatedButton(
      onPressed: () =>
          _showJobDetails(context, job), // Redirect to details to apply
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, color: theme.colorScheme.onPrimary, size: 20),
          const SizedBox(width: 6),
          Text(
            "Quick Apply",
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterModal(
        theme: theme,
        initialFilters: _currentFilters,
        onApply: (filters) {
          setState(() => _currentFilters = filters);
          Provider.of<JobProvider>(context, listen: false).fetchJobs(
            easyApply: filters['easyApply'] != true
                ? filters['easyApply']
                : null,
            activelyHiring: filters['activelyHiring'] != true
                ? filters['activeHiring']
                : null,
            location:
                filters['location'] != null &&
                    filters['location'].toString().isNotEmpty
                ? filters['location']
                : null,
            workMode: filters['workMode'],
            experienceLevel: filters['expLevel'] != 'All Levels'
                ? filters['expLevel']
                : null,
            jobType: filters['jobType'] != 'Full-time'
                ? filters['jobType']
                : null,
            companyType: filters['companyType'],
            industry: filters['industryType'],
            minSalary:
                (filters['salaryRange'] as RangeValues).start.round() * 1000,
            maxSalary:
                (filters['salaryRange'] as RangeValues).end.round() * 1000,
          );
        },
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchModal(
        theme: theme,
        onSearch: (keywords, location) {
          Provider.of<JobProvider>(
            context,
            listen: false,
          ).fetchJobs(title: keywords, location: location);
        },
      ),
    );
  }

  //   void _showPostJobModal(BuildContext context) {
  //   final theme = Theme.of(context);
  //   debugPrint("post job api called");
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => _PostJobModal(
  //       theme: theme,
  //       onJobPosted: (newJob) async {
  //         try {
  //           await Provider.of<JobProvider>(
  //             context,
  //             listen: false,
  //           ).createJob(newJob);
  //
  //           if (!context.mounted) return;
  //
  //           Navigator.pop(context); // close modal ONLY on success
  //
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text("Job posted successfully!")),
  //           );
  //         } catch (e) {
  //           if (!context.mounted) return;
  //
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text("Failed to post job: $e")),
  //           );
  //         }
  //       },
  //
  //     ),
  //   );
  // }

  void _showPostJobModal(BuildContext context, {Job? jobToEdit}) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostJobModal(
        theme: theme,
        job: jobToEdit,
        onJobPosted: (jobData) async {
          try {
            final provider = Provider.of<JobProvider>(context, listen: false);
            
            if (jobToEdit != null) {
              await JobService().updateJob(jobToEdit.id, jobData);
               // Update provider if needed, or just reload
            } else {
              await provider.createJob(jobData);
            }

            if (!context.mounted) return;

            Navigator.pop(ctx); // ✅ close ONLY on success

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jobToEdit != null ? "Job updated successfully!" : "Job posted successfully!")),
            );
            
            // Reload data to reflect changes
            _loadData();
          } catch (e) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        },
      ),
    );
  }
  void _editJob(Job job) {
    _showPostJobModal(context, jobToEdit: job);
  }

  void _deleteJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await JobService().deleteJob(job.id);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Job deleted successfully')),
           );
           _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete job: $e')),
          );
        }
      }
    }
  }


  void _showAnalyticsModal(BuildContext context, Job job) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: JobApplicantsView(
        jobId: job.id,
        jobTitle: job.title,
      ),
    )));
  }

  void _showJobDetails(BuildContext context, Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final ThemeData theme;
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApply;
  const _FilterModal({
    required this.theme,
    this.initialFilters,
    required this.onApply,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  bool easyApply = true;
  bool activelyHiring = true;
  String experienceLevel = "All Levels";
  String location = "";
  String workMode = "";
  String jobType = "";
  String companyType = "";
  String industryType = "";
  List<Skill> Skills = [];
  RangeValues salaryRange = const RangeValues(50, 500);

  late TextEditingController _locationController;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters ?? {};
    easyApply = f['easyApply'] ?? true;
    activelyHiring = f['activelyHiring'] ?? true;
    experienceLevel = f['expLevel'] ?? "All Levels";
    jobType = f['jobType'] ?? "";
    salaryRange = f['salaryRange'] ?? const RangeValues(50, 500);

    _locationController = TextEditingController(text: f['location'] ?? "");
    workMode = f['workMode'] ?? "";
    companyType = f['companyType'] ?? "";
    industryType = f['industryType'] ?? "";
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16), // Changed from 12 to 16
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: widget.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            easyApply = true;
                            activelyHiring = true;
                            experienceLevel = "All Levels";
                            jobType = "";
                            workMode = "";
                            companyType = "";
                            industryType = "";
                            Skills = [];
                            salaryRange = const RangeValues(50, 500);
                            _locationController.clear();
                            _locationError = null;
                          });
                        },
                        child: Text(
                          "Clear all",
                          style: TextStyle(color: widget.theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _switchOption(
                    "Easy Apply",
                    easyApply,
                    (v) => setState(() => easyApply = v),
                  ),
                  _switchOption(
                    "Actively Hiring",
                    activelyHiring,
                    (v) => setState(() => activelyHiring = v),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Location",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.surfaceContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _locationController,
                      style: widget.theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "Add city...",
                        hintStyle: widget.theme.textTheme.bodySmall,
                        border: InputBorder.none,
                        errorText: _locationError,
                      ),
                      onChanged: (v) {
                        if (_locationError != null) {
                          setState(() => _locationError = null);
                        }
                      },
                    ),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Salary Range",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: salaryRange,
                    min: 0,
                    max: 500,
                    divisions: 50,
                    labels: RangeLabels(
                      "${salaryRange.start.round()}k",
                      "${salaryRange.end.round()}k",
                    ),
                    activeColor: widget.theme.primaryColor,
                    onChanged: (v) => setState(() => salaryRange = v),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Experience Level",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children:
                        ["All Levels", "Entry Level", "Mid Level", "Senior"]
                            .map(
                              (e) => _choiceChip(
                                e,
                                experienceLevel == e,
                                (s) => setState(() => experienceLevel = e),
                              ),
                            )
                            .toList(),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Job Type",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children:
                        ["Full-time", "Part-time", "Contract", "Internship"]
                            .map(
                              (e) => _choiceChip(
                                e,
                                jobType == e,
                                (s) => setState(() => jobType = e),
                              ),
                            )
                            .toList(),
                  ),
                  // const SizedBox(height: 100),
                  // Add this after the Job Type section in your Column
                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Work Mode",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: ["Onsite", "Remote", "Hybrid"]
                        .map(
                          (e) => _choiceChip(
                            e,
                            workMode == e,
                            (s) => setState(() => workMode = e),
                          ),
                        )
                        .toList(),
                  ),

                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Company Type",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: ["MNC", "Startup", "Government", "NGO"]
                        .map(
                          (e) => _choiceChip(
                            e,
                            companyType == e,
                            (s) => setState(() => companyType = e),
                          ),
                        )
                        .toList(),
                  ),

                  Divider(color: widget.theme.dividerColor, height: 40),
                  Text(
                    "Industry",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children:
                        ["Technology", "Finance", "Healthcare", "Education"]
                            .map(
                              (e) => _choiceChip(
                                e,
                                industryType == e,
                                (s) => setState(() => industryType = e),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () {
                widget.onApply({
                  'easyApply': easyApply,
                  'activelyHiring': activelyHiring,
                  'expLevel': experienceLevel,
                  'jobType': jobType,
                  'workMode': workMode,
                  'companyType': companyType,
                  'industryType': industryType,
                  'salaryRange': salaryRange,
                  'location': _locationController.text.trim(),
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                "Show Results",
                style: TextStyle(
                  color: widget.theme.colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchOption(String title, bool val, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: widget.theme.textTheme.bodyLarge),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: widget.theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: widget.theme.primaryColor,
      backgroundColor: widget.theme.colorScheme.surfaceContainer,
      labelStyle: TextStyle(
        color: selected
            ? widget.theme.colorScheme.onPrimary
            : widget.theme.textTheme.bodyMedium?.color,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? widget.theme.primaryColor
              : widget.theme.dividerColor,
        ),
      ),
    );
  }
}

class _SearchModal extends StatefulWidget {
  final ThemeData theme;
  final Function(String keywords, String location) onSearch;
  const _SearchModal({required this.theme, required this.onSearch});
  @override
  State<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<_SearchModal> {
  final TextEditingController keywordsController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              "Search Jobs",
              style: widget.theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Keywords",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _searchInput(
                    Icons.search,
                    "Type Job title ...",
                    keywordsController,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Location",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _searchInput(
                    Icons.location_on_outlined,
                    "Type city & hit Enter...",
                    locationController,
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSearch(
                        keywordsController.text,
                        locationController.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Search Results",
                      style: TextStyle(
                        color: widget.theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _searchInput(
    IconData icon,
    String hint,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.theme.dividerColor),
      ),
      child: TextField(
        controller: controller,
        style: widget.theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: widget.theme.textTheme.bodySmall,
          prefixIcon: Icon(
            icon,
            color: widget.theme.textTheme.bodySmall?.color,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}


