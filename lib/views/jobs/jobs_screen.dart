import 'package:flutter/material.dart';
import '../bottom_navigation.dart';
import '../../widgets/app_top_bar.dart';
import 'job_posts_dashboard.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/local_job_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int mainTab = 0; // 0: View Jobs, 1: My Jobs, 2: Offers
  int subTab = 0; // 0: In Progress, 1: Applied, 2: In Past, 3: Saved, 4: Hiring

  final List<Map<String, dynamic>> _allViewJobs = [];

  late List<Map<String, dynamic>> viewJobs;

  @override
  void initState() {
    super.initState();
    viewJobs = List.from(_allViewJobs);
    _loadUserData();
  }

  final List<Map<String, dynamic>> myJobsInProgress = [];

  final List<Map<String, dynamic>> myJobsApplied = [];

  final List<Map<String, dynamic>> myJobsInPast = [];

  final List<Map<String, dynamic>> offers = [];

  final List<Map<String, dynamic>> myJobsSaved = [];
  final List<Map<String, dynamic>> myJobsHiring = [];
  final List<Map<String, dynamic>> myPostedJobs = [];
  
  final _localJobService = LocalJobService();



  Future<void> _loadUserData() async {
    final posted = await _localJobService.getPostedJobs();
    final applied = await _localJobService.getAppliedJobs();
    final saved = await _localJobService.getSavedJobs();
    
    if (mounted) {
      setState(() {
        myPostedJobs.clear();
        myPostedJobs.addAll(posted);
        
        myJobsApplied.clear();
        myJobsApplied.addAll(applied);
        
        myJobsSaved.clear();
        myJobsSaved.addAll(saved);
        
        // Update dashboard view if needed
        if (myJobsHiring.isEmpty && myPostedJobs.isNotEmpty) {
           myJobsHiring.addAll(myPostedJobs);
        }

        // Merge posted jobs into main feed (View Jobs)
        if (myPostedJobs.isNotEmpty) {
           final existingIds = _allViewJobs.map((j) => j['id']).toSet();
           final newJobs = myPostedJobs.where((j) => !existingIds.contains(j['id'])).toList();
           if (newJobs.isNotEmpty) {
             _allViewJobs.insertAll(0, newJobs);
             viewJobs = List.from(_allViewJobs);
           }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppTopBar(
        key: const ValueKey('jobs_appbar_v2'), // Force rebuild to remove icon
        searchType: SearchType.jobs,
        onSearchTap: () => _showSearchModal(context),
        onFilterTap: null, // Explicitly null to ensure no filter icon in search bar
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          await _loadUserData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _postJobHeader(theme)),
            SliverToBoxAdapter(child: _tabs(theme)),
            _contentArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _postJobHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Post Job Button (First and Expanded)
          Expanded(
            child: GestureDetector(
              onTap: () => _showPostJobModal(context),
              child: Container(
                padding: const EdgeInsets.all(12), // Slightly reduced padding for "small" feel
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
                    const SizedBox(width: 12),
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
                            "Find the right talent", // Shortened text to fit better
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button (Second)
          Expanded(
            child: GestureDetector(
              onTap: () => _showFilterModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center content
                  children: [
                    Icon(
                      Icons.tune,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Filter",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(ThemeData theme) {
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
                _tabPill(theme, "Offers", 2, badge: "2"),
                _tabPill(theme, "Job Posts Dashboard", 3), // New Tab
              ],
            ),
          ),
          if (mainTab == 1) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _subTabPill(theme, "In Progress", 0),
                  _subTabPill(theme, "Applied", 1),
                  _subTabPill(theme, "In Past", 2),
                  _subTabPill(theme, "Saved", 3),
                  _subTabPill(theme, "Hiring", 4),
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
        setState(() => mainTab = index);
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
      onTap: () => setState(() => subTab = index),
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

  Widget _contentArea(ThemeData theme) {
    // 1. Dashboard View
    if (mainTab == 3) {
      return JobPostsDashboard(postedJobs: myPostedJobs);
    }

    // 2. Other Views
    List<Map<String, dynamic>> list = [];
    bool isHiringView = false;

    if (mainTab == 0) {
      list = viewJobs;
    } else if (mainTab == 1) {
      if (subTab == 0) {
        list = myJobsInProgress;
      } else if (subTab == 1) {
        list = myJobsApplied;
      } else if (subTab == 2) {
        list = myJobsInPast;
      } else if (subTab == 3) {
        list = myJobsSaved;
      } else if (subTab == 4) {
        list = myJobsHiring;
        isHiringView = true;
      }
    } else if (mainTab == 2) {
      list = offers;
    }

    if (list.isEmpty) {
      return SliverToBoxAdapter(child: _emptyState(theme));
    }


    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _jobCard(theme, list[index], isHiringView: isHiringView),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
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
              "No jobs found matching your criteria.",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  viewJobs = List.from(_allViewJobs);
                });
              },
              child: Text(
                "Clear filters",
                style: TextStyle(color: theme.primaryColor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobCard(
    ThemeData theme,
    Map<String, dynamic> job, {
    bool isHiringView = false,
  }) {
    bool isMyJob = mainTab == 1;
    bool isSaved = job['isSaved'] ?? false;

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
                child: Text(
                  job['initial'],
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
                      job['title'],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isMyJob &&
                        job.containsKey('status') &&
                        !isHiringView) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (job['statusColor'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          job['status'],
                          style: TextStyle(
                            color: job['statusColor'],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(job['company'], style: theme.textTheme.bodyLarge),
                        Icon(
                          Icons.circle,
                          size: 4,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        Text(
                          job['location'],
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (job['isHiring'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
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
                onPressed: () => _toggleSaveJob(job),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow(theme, job),
          const SizedBox(height: 12),
          _matchPill(theme, job['match']),
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
          if (isMyJob && job.containsKey('timelineStep') && !isHiringView) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                "Application Timeline",
                style: theme.textTheme.bodyMedium,
              ),
            ),
            _timeline(theme, job['timelineStep']),
          ],
        ],
      ),
    );
  }

  void _toggleSaveJob(Map<String, dynamic> job) {
    setState(() {
      bool isSaved = !(job['isSaved'] ?? false);
      job['isSaved'] = isSaved;
      if (isSaved) {
        if (!myJobsSaved.any((j) => j['id'] == job['id'])) {
          myJobsSaved.insert(0, Map.from(job));
        }
      } else {
        myJobsSaved.removeWhere((j) => j['id'] == job['id']);
        void updateIsSaved(List<Map<String, dynamic>> list) {
          for (var item in list) {
            if (item['id'] == job['id']) item['isSaved'] = false;
          }
        }

        updateIsSaved(viewJobs);
        updateIsSaved(myJobsInProgress);
        updateIsSaved(myJobsApplied);
        updateIsSaved(myJobsInPast);
        updateIsSaved(offers);
        updateIsSaved(myJobsHiring);
      }
      _localJobService.saveSavedJobs(myJobsSaved);
    });
  }

  Widget _infoRow(ThemeData theme, Map<String, dynamic> job) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _pill(theme, Icons.work_outline, job['type']),
        _pill(theme, Icons.attach_money, job['salary']),
        _pill(theme, Icons.access_time, job['time']),
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

  Widget _matchPill(ThemeData theme, String match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: theme.colorScheme.secondary, size: 18),
          const SizedBox(width: 6),
          Text(
            "$match Match",
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerInfo(ThemeData theme, Map<String, dynamic> job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
            const SizedBox(width: 10),
            Text(job['response'], style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(job['applicants'], style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _actionButtons(ThemeData theme, Map<String, dynamic> job) {
    if (mainTab == 1 && subTab == 1) {
      return Row(
        children: [
          Expanded(child: _detailsBtn(theme, job)),
          const SizedBox(width: 16),
          _appliedStatusBtn(theme),
        ],
      );
    }
    if (mainTab == 1 && (subTab == 0 || subTab == 2)) {
      return _detailsBtn(theme, job, fullWidth: true);
    }
    return Row(
      children: [
        Expanded(child: _detailsBtn(theme, job)),
        const SizedBox(width: 16),
        Expanded(child: _quickApplyBtn(theme, job)),
      ],
    );
  }

  Widget _hiringActionButtons(ThemeData theme, Map<String, dynamic> job) {
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
              "Analytics",
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

  Widget _detailsBtn(
    ThemeData theme,
    Map<String, dynamic> job, {
    bool fullWidth = false,
  }) {
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

  Widget _quickApplyBtn(ThemeData theme, Map<String, dynamic> job) {
    return ElevatedButton(
      onPressed: () => _showApplyModal(context, job),
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

  Widget _timeline(ThemeData theme, int step) {
    final stages = ["Applied", "Under Review", "Interview", "Offer"];
    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            bool done = i <= step;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: done ? theme.primaryColor : theme.dividerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < step
                            ? theme.primaryColor
                            : theme.dividerColor,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) {
            bool active = i == step;
            return Text(
              stages[i],
              style: TextStyle(
                color: active
                    ? theme.primaryColor
                    : theme.textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
        ),
      ],
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
        onApply: (filters) {
          setState(() {
            viewJobs = _allViewJobs.where((job) {
              bool matches = true;
              if (filters['remoteOnly'] == true) {
                if (job['workMode'] != 'Remote') matches = false;
              }
              if (filters['expLevel'] != 'All Levels') {
                if (job['expLevel'] != filters['expLevel']) matches = false;
              }
              if (filters['jobType'] != 'Full-time') {
                if (job['type'] != filters['jobType']) matches = false;
              }
              int salary = job['salaryVal'] ?? 0;
              if (salary < filters['salaryRange'].start ||
                  salary > filters['salaryRange'].end) {
                matches = false;
              }
              return matches;
            }).toList();
          });
        },
      ),
    );
  }

  void _showApplyModal(BuildContext context, Map<String, dynamic> job) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApplyModal(
        theme: theme,
        job: job,
        onApplied: (appliedJob) {
          setState(() {
            viewJobs.removeWhere((j) => j['id'] == appliedJob['id']);
            offers.removeWhere((j) => j['id'] == appliedJob['id']);
            myJobsApplied.insert(0, {
              ...appliedJob,
              'status': 'Applied',
              'statusColor': Colors.blueAccent,
              'time': 'Applied Just now',
              'timelineStep': 0,
            });
            _localJobService.saveAppliedJobs(myJobsApplied);
            mainTab = 1;
            subTab = 1;
          });
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
          setState(() {
            viewJobs = _allViewJobs.where((job) {
              bool matches = true;
              if (keywords.isNotEmpty) {
                String title = job['title'].toString().toLowerCase();
                String company = job['company'].toString().toLowerCase();
                if (!title.contains(keywords.toLowerCase()) &&
                    !company.contains(keywords.toLowerCase())) {
                  matches = false;
                }
              }
              if (location.isNotEmpty) {
                String loc = job['location'].toString().toLowerCase();
                if (!loc.contains(location.toLowerCase())) {
                  matches = false;
                }
              }
              return matches;
            }).toList();
          });
        },
      ),
    );
  }

  void _showPostJobModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostJobModal(
        theme: theme,
        onJobPosted: (newJob) {
          setState(() {
            _allViewJobs.insert(0, newJob);
            viewJobs = List.from(_allViewJobs);
            myJobsHiring.insert(0, newJob);
            myPostedJobs.insert(0, newJob);
            _localJobService.savePostedJobs(myPostedJobs);
            mainTab = 1;
            subTab = 4;
          });
        },
      ),
    );
  }

  void _showAnalyticsModal(BuildContext context, Map<String, dynamic> job) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnalyticsModal(theme: theme, job: job),
    );
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _JobDetailsPage(
          job: job,
          onApply: () => _showApplyModal(context, job),
          onToggleSave: () => _toggleSaveJob(job),
        ),
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final ThemeData theme;
  final Function(Map<String, dynamic>) onApply;
  const _FilterModal({required this.theme, required this.onApply});
  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  bool easyApply = false;
  bool activelyHiring = false;
  bool remoteOnly = false;
  String experienceLevel = "All Levels";
  String jobType = "Full-time";
  double salaryRange = 100; // Changed from RangeValues to double
  final TextEditingController locationController = TextEditingController();

  // New Filter States
  final Map<String, bool> workMode = {
    'Remote': false,
    'Hybrid': false,
    'Onsite': false,
  };

  final Map<String, bool> companyType = {
    'Startup': false,
    'MNC': false,
    'Product-based': false,
    'Service-based': false,
  };

  final Map<String, bool> industry = {
    'Technology': false,
    'Finance': false,
    'Healthcare': false,
    'Education': false,
    'Retail': false,
  };

  @override
  void dispose() {
    locationController.dispose();
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
                            easyApply = false;
                            activelyHiring = false;
                            remoteOnly = false;
                            experienceLevel = "All Levels";
                            jobType = "Full-time";
                            salaryRange = 100; // Reset to default double value
                            locationController.clear();
                            workMode.updateAll((key, value) => false);
                            companyType.updateAll((key, value) => false);
                            industry.updateAll((key, value) => false);
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
                  _switchOption(
                    "Remote Only",
                    remoteOnly,
                    (v) => setState(() => remoteOnly = v),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),

                  // --- NEW: Work Mode ---
                  _checkboxSection("Work Mode", workMode),
                  Divider(color: widget.theme.dividerColor, height: 24),

                  // --- NEW: Location ---
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
                      style: widget.theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "Add city...",
                        hintStyle: widget.theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Divider(color: widget.theme.dividerColor, height: 40),

                  // --- NEW: Company Type ---
                  _checkboxSection("Company Type", companyType),
                  Divider(color: widget.theme.dividerColor, height: 24),

                  // --- NEW: Industry ---
                  _checkboxSection("Industry", industry),
                  Divider(color: widget.theme.dividerColor, height: 24),

                  Text(
                    "Salary Range (k/year)",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$0k",
                        style: widget.theme.textTheme.bodyMedium,
                      ),
                      Text(
                        "\$${salaryRange.toInt()}k",
                        style: TextStyle(
                          color: widget.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: salaryRange,
                    min: 0,
                    max: 200,
                    activeColor: widget.theme.primaryColor,
                    onChanged: (val) => setState(() => salaryRange = val),
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
                  const SizedBox(height: 100),
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
                  'remoteOnly': remoteOnly,
                  'expLevel': experienceLevel,
                  'jobType': jobType,
                  'salaryRange': salaryRange,
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

  Widget _checkboxSection(String title, Map<String, bool> items) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: widget.theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: true,
        children: items.keys.map((key) {
          return CheckboxListTile(
            title: Text(key, style: widget.theme.textTheme.bodyMedium),
            value: items[key],
            activeColor: widget.theme.primaryColor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                items[key] = val ?? false;
              });
            },
          );
        }).toList(),
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
                  const SizedBox(height: 16),
                  _searchInput(
                    Icons.search,
                    "Job title, keywords, or company",
                    keywordsController,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Locations",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _searchInput(
                    Icons.location_on_outlined,
                    "Type city & hit Enter...",
                    locationController,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Type a city name and press Enter to add it",
                    style: widget.theme.textTheme.bodySmall,
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

class _ApplyModal extends StatefulWidget {
  final ThemeData theme;
  final Map<String, dynamic> job;
  final Function(Map<String, dynamic>) onApplied;

  const _ApplyModal({
    required this.theme,
    required this.job,
    required this.onApplied,
  });

  @override
  State<_ApplyModal> createState() => _ApplyModalState();
}

class _ApplyModalState extends State<_ApplyModal> {
  String? _uploadedFileName;

  void _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _uploadedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      // Handle potential permission errors or other issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Apply to ${widget.job['title']}",
                  style: widget.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: widget.theme.textTheme.bodySmall?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Full Name",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field("Alex Doe"),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email",
                              style: widget.theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _field("alex@example.com"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Phone (Optional)",
                              style: widget.theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _field(""),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Resume",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _resumeUpload(),
                  const SizedBox(height: 24),
                  Text(
                    "Cover Note (Optional)",
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field("", maxLines: 4),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_uploadedFileName == null) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please upload your resume first."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      widget.onApplied(widget.job);
                      // Navigator.pop handled by onApplied or below?
                      // The original onApplied implementation also did pop.
                      // We will rely on onApplied implementation from parent to pop.
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Application submitted successfully!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Submit Application",
                      style: TextStyle(
                        color: widget.theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      style: widget.theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: widget.theme.textTheme.bodySmall,
        filled: true,
        fillColor: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _resumeUpload() {
    bool isUploaded = _uploadedFileName != null;
    return GestureDetector(
      onTap: _pickResume,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isUploaded 
              ? Colors.green.withValues(alpha: 0.1) 
              : widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded ? Colors.green : widget.theme.dividerColor,
            width: isUploaded ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_outline : Icons.upload_outlined,
              color: isUploaded ? Colors.green : widget.theme.textTheme.bodySmall?.color,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              isUploaded ? _uploadedFileName! : "Upload Resume",
              style: TextStyle(
                color: isUploaded ? Colors.green : widget.theme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!isUploaded)
              Text(
                "PDF, DOCX up to 5MB",
                style: TextStyle(
                  color: widget.theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
             if (isUploaded)
              Text(
                "Tap to change",
                style: TextStyle(
                  color: widget.theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _PostJobModal extends StatefulWidget {
  final ThemeData theme;
  final Function(Map<String, dynamic>) onJobPosted;
  const _PostJobModal({required this.theme, required this.onJobPosted});
  @override
  State<_PostJobModal> createState() => _PostJobModalState();
}

class _PostJobModalState extends State<_PostJobModal> {
  String empType = "Full-time";
  String workMode = "Onsite";
  bool enableEasyApply = true;
  bool activelyHiring = true;
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final salaryController = TextEditingController();
  final descriptionController = TextEditingController();
  final skillsController = TextEditingController();
  final companyController = TextEditingController();
  final aboutCompanyController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Post a Job",
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: widget.theme.textTheme.bodySmall?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new job listing to find the best talent.",
            style: widget.theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Job Details"),
                  _inputLabel("Job Title *"),
                  _textField(titleController, "e.g. Senior Frontend Engineer"),
                  _inputLabel("Employment Type *"),
                  _dropdown(empType, [
                    "Full-time",
                    "Part-time",
                    "Contract",
                    "Freelancer",
                    "Internship",
                  ], (v) => setState(() => empType = v!)),
                  _inputLabel("Location *"),
                  _textField(locationController, "e.g. San Francisco, CA"),
                  _inputLabel("Work Mode *"),
                  _dropdown(workMode, [
                    "Onsite",
                    "Hybrid",
                    "Remote",
                  ], (v) => setState(() => workMode = v!)),
                  _inputLabel("Salary Range"),
                  _textField(salaryController, "e.g. \$120k - \$160k"),
                  _inputLabel("Description"),
                  _textField(
                    descriptionController,
                    "Describe the role, responsibilities, and requirements...",
                    maxLines: 4,
                  ),
                  _inputLabel("Skills (comma separated)"),
                  _textField(
                    skillsController,
                    "e.g. React, TypeScript, Tailwind CSS",
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader("Company Information"),
                  _inputLabel("Company Name *"),
                  _textField(companyController, "e.g. Google"),
                  _inputLabel("About Company"),
                  _textField(
                    aboutCompanyController,
                    "Brief description about the company...",
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader("Settings"),
                  _checkboxOption(
                    "Enable Easy Apply",
                    "Allow candidates to apply with one click",
                    enableEasyApply,
                    (v) => setState(() => enableEasyApply = v!),
                  ),
                  _checkboxOption(
                    "Actively Hiring Badge",
                    "Show an 'Actively Hiring' badge on the job card",
                    activelyHiring,
                    (v) => setState(() => activelyHiring = v!),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: widget.theme.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: widget.theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isEmpty ||
                                companyController.text.isEmpty) {
                              return;
                            }
                            final newJob = {
                              'id': DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              'title': titleController.text,
                              'company': companyController.text,
                              'initial': companyController.text[0]
                                  .toUpperCase(),
                              'salary': salaryController.text.isEmpty
                                  ? 'Negotiable'
                                  : salaryController.text,
                              'salaryVal': 100,
                              'location': locationController.text,
                              'type': empType,
                              'workMode': workMode,
                              'time': 'Just now',
                              'applicants': '0 applicants applied',
                              'match': '100%',
                              'response': 'New job listing',
                              'isHiring': activelyHiring,
                              'isSaved': false,
                              'isEasyApply': enableEasyApply,
                            };
                            widget.onJobPosted(newJob);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Post Job",
                            style: TextStyle(
                              color: widget.theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: widget.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: widget.theme.dividerColor, height: 24),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: widget.theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: widget.theme.textTheme.bodySmall,
        filled: true,
        fillColor: widget.theme.colorScheme.surfaceContainer.withValues(
          alpha: 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.theme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: widget.theme.textTheme.bodyLarge),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: widget.theme.cardColor,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: widget.theme.textTheme.bodySmall?.color,
          ),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _checkboxOption(
    String title,
    String sub,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.dividerColor),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: widget.theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(sub, style: widget.theme.textTheme.bodySmall),
        activeColor: widget.theme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _AnalyticsModal extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> job;
  const _AnalyticsModal({required this.theme, required this.job});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Job Analytics",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.textTheme.bodySmall?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _statCard(
            "Total Applicants",
            job['applicants'].toString().split(' ')[0],
          ),
          const SizedBox(height: 16),
          _statCard("Views", "142"),
          const SizedBox(height: 16),
          _statCard("Saves", "12"),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "View Applicants List",
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            val,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final VoidCallback onApply;
  final VoidCallback onToggleSave;
  const _JobDetailsPage({
    required this.job,
    required this.onApply,
    required this.onToggleSave,
  });
  @override
  State<_JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<_JobDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isSaved = widget.job['isSaved'] ?? false;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.job['title'],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: Text(
                      widget.job['initial'],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.job['title'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        color: theme.textTheme.bodySmall?.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.job['company'],
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.textTheme.bodySmall?.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.job['location'],
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.textTheme.bodySmall?.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.job['time'],
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tag(theme, widget.job['type']),
                      const SizedBox(width: 8),
                      _tag(theme, "Hybrid"),
                      const SizedBox(width: 8),
                      _tag(theme, widget.job['salary'], isGreen: true),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: widget.onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          "Quick Apply",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      widget.onToggleSave();
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(
                        color: isSaved
                            ? theme.colorScheme.secondary
                            : theme.dividerColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved
                              ? theme.colorScheme.secondary
                              : theme.iconTheme.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSaved ? "Saved" : "Save Job",
                          style: TextStyle(
                            color: isSaved
                                ? theme.colorScheme.secondary
                                : theme.textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              theme,
              "About the Job",
              "We are looking for a talented individual to join our growing team. You will be working on cutting-edge technologies and solving complex problems.",
            ),
            const SizedBox(height: 24),
            Text(
              "Skills Required",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                "React",
                "TypeScript",
                "Node.js",
                "Design Systems",
              ].map((s) => _skillTag(theme, s)).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Recruiter Insights",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.job['response'],
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Match",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.job['match'],
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        double.parse(widget.job['match'].replaceAll('%', '')) /
                        100,
                    backgroundColor: theme.dividerColor,
                    color: theme.primaryColor,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              theme,
              "About ${widget.job['company']}",
              "We are a leading company in our industry, dedicated to innovation and excellence.",
            ),
            const SizedBox(height: 16),
            _companyInfoRow(theme, "Industry", "Technology"),
            _companyInfoRow(theme, "Type", "MNC"),
            _companyInfoRow(theme, "Headquarters", widget.job['location']),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tag(ThemeData theme, String text, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGreen
            ? Colors.green.withValues(alpha: 0.1)
            : theme.dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isGreen
              ? Colors.greenAccent
              : theme.textTheme.bodyMedium?.color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _skillTag(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(text, style: theme.textTheme.bodyLarge),
    );
  }

  Widget _section(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
      ],
    );
  }

  Widget _companyInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
