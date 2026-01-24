import 'package:flutter/material.dart';
import 'job_details_screen.dart';
import '../../widgets/app_top_bar.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  /* ================= THEME ================= */
  final Color bg = const Color(0xFF0B1220);
  final Color card = const Color(0xFF1F2937);
  final Color border = const Color(0xFF2D3748);
  // SEARCH STATE
  bool expandSearch = false;
  String keyword = '';


  final Gradient gradient =
  const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]);

  /* ================= TABS ================= */
  int tab = 0;
  final tabs = ['In Progress', 'Applied', 'In Past', 'Saved'];

  /* ================= FILTER STATE ================= */
  bool fullTime = false;
  bool partTime = false;
  bool contract = false;
  bool remote = false;
  bool internship = false;

  String location = '';
  String experience = 'All Levels';

  bool showFilter = false;

  /* ================= JOB DATA ================= */
  final List<Map<String, dynamic>> jobs = [
    {
      'title': 'Senior Product Analyst',
      'company': 'Netflix',
      'location': 'New York, NY',
      'type': 'Full-time',
      'experience': 'Senior Level',
      'status': 'Applied',
      'time': 'Applied 2 days ago',
    },
    {
      'title': 'UX Researcher',
      'company': 'Spotify',
      'location': 'Remote',
      'type': 'Remote',
      'experience': 'Mid Level',
      'status': 'In Past',
      'time': 'Closed 1 week ago',
    },
    {
      'title': 'Product Owner',
      'company': 'Stripe',
      'location': 'San Francisco, CA',
      'type': 'Full-time',
      'experience': 'Senior Level',
      'status': 'Saved',
      'time': 'Saved yesterday',
    },
    {
      'title': 'Product Designer',
      'company': 'Adobe',
      'location': 'Remote',
      'type': 'Remote',
      'experience': 'Mid Level',
      'status': 'In Progress',
      'time': 'Interview scheduled',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppTopBar(
        searchType: SearchType.jobs,
        onFilterTap: () => setState(() => showFilter = true),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _tabsRow(),
              Expanded(child: _jobList()),
            ],
          ),

          if (showFilter) _filterOverlay(),
        ],
      ),
    );
  }

  /* ================= TABS ================= */
  Widget _tabsRow() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = tab == i;
          return GestureDetector(
            onTap: () => setState(() => tab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? gradient : null,
                color: active ? null : card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(tabs[i],
                  style: const TextStyle(color: Colors.white)),
            ),
          );
        }),
      ),
    );
  }

  /* ================= FILTERED JOBS (FIXED) ================= */
  List<Map<String, dynamic>> _filteredJobs() {
    return jobs.where((job) {
      // TAB STATUS FILTER
      if (job['status'] != tabs[tab]) return false;

      // LOCATION FILTER
      if (location.isNotEmpty &&
          !job['location']
              .toLowerCase()
              .contains(location.toLowerCase())) {
        return false;
      }

      // EXPERIENCE FILTER
      if (experience != 'All Levels' &&
          job['experience'] != experience) {
        return false;
      }

      // JOB TYPE FILTER
      if ((fullTime || partTime || contract || remote || internship) &&
          ![
            if (fullTime) 'Full-time',
            if (partTime) 'Part-time',
            if (contract) 'Contract',
            if (remote) 'Remote',
            if (internship) 'Internship',
          ].contains(job['type'])) {
        return false;
      }

      return true;
    }).toList();
  }

  /* ================= JOB LIST ================= */
  Widget _jobList() {
    final filtered = _filteredJobs();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        ...filtered.map(_jobCard),
      ],
    );
  }

  /* ================= JOB CARD ================= */
  Widget _jobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: gradient,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['title'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(job['company'],
                        style:
                        const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(job['location'],
                            style: const TextStyle(
                                color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(job['time'],
                        style: const TextStyle(
                            color: Colors.blueAccent, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  text: 'View Details',
                  filled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(job: job),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  text: tab == 1
                      ? 'Withdraw'
                      : tab == 3
                      ? 'Remove'
                      : 'View Details',
                  filled: false,
                  danger: tab == 1,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required bool filled,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF111827)
              : danger
              ? Colors.red
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  /* ================= FILTER OVERLAY ================= */
  Widget _filterOverlay() {
    return GestureDetector(
      onTap: () => setState(() => showFilter = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  _section('Job Type'),
                  _check('Full-time', fullTime,
                          (v) => setState(() => fullTime = v)),
                  _check('Part-time', partTime,
                          (v) => setState(() => partTime = v)),
                  _check('Contract', contract,
                          (v) => setState(() => contract = v)),
                  _check('Remote', remote,
                          (v) => setState(() => remote = v)),
                  _check('Internship', internship,
                          (v) => setState(() => internship = v)),

                  const SizedBox(height: 16),
                  _section('Location'),
                  _input(),

                  _dropdown('Experience Level', experience, [
                    'All Levels',
                    'Entry Level',
                    'Mid Level',
                    'Senior Level',
                  ], (v) => setState(() => experience = v!)),

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => showFilter = false),
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Apply Filters',
                          style: TextStyle(
                              color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(color: Colors.white70)),
  );

  Widget _check(String text, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v!),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      activeColor: Colors.indigo,
      checkColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _input() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Type city...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        onChanged: (v) => setState(() => location = v),
      ),
    );
  }

  Widget _dropdown(String title, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: bg,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white54),
                items: items
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
