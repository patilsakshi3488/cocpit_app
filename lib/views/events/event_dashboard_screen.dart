import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'package:intl/intl.dart';

class EventDashboardScreen extends StatefulWidget {
  const EventDashboardScreen({super.key});

  @override
  State<EventDashboardScreen> createState() => _EventDashboardScreenState();
}

class _EventDashboardScreenState extends State<EventDashboardScreen> {
  // Mock Stats variables
  int totalEvents = 0;
  int activeEvents = 0;
  int ticketsSold = 0;
  double totalRevenue = 0.0;

  List<EventModel> _myEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final events = await EventService.getMyCreatedEvents();
      setState(() {
        _myEvents = events;
        totalEvents = events.length;
        activeEvents = events.where((e) => e.endTimeDt.isAfter(DateTime.now())).length;
        
        // Mock data for tickets/revenue since backend doesn't support it yet
        ticketsSold = events.fold(0, (sum, e) => sum + e.registeredCount);
        totalRevenue = ticketsSold * 15.0; // Mock avg price $15
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter events
    final filteredEvents = _myEvents.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Manage and track your events',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          
          // Top Stats Grid (2x2)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5, // Adjust for card shape
            children: [
              _StatCard(title: 'All Events', value: totalEvents.toString(), icon: Icons.calendar_today, color: Colors.blue),
              _StatCard(title: 'Active Events', value: activeEvents.toString(), icon: Icons.schedule, color: Colors.orange),
              _StatCard(title: 'Tickets Sold', value: ticketsSold.toString(), subText: 'Capacity: ${totalEvents * 100}', icon: Icons.people, color: Colors.purple),
              _StatCard(title: 'Total Revenue', value: '\$${NumberFormat("#,##0").format(totalRevenue)}', icon: Icons.attach_money, color: Colors.green),
            ],
          ),

          const SizedBox(height: 32),

          // "Your Events" Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Your Events", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (_myEvents.isNotEmpty)
                Text("${_myEvents.length} events", style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),

          if (filteredEvents.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No events found")))
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _DashboardEventCard(
                event: filteredEvents[i],
                theme: theme,
                onViewDetails: () => _openEventAnalytics(context, filteredEvents[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _openEventAnalytics(BuildContext context, EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EventAnalyticsDetailScreen(event: event),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subText;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({required this.title, required this.value, this.subText, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
              if (subText != null)
                 Text(subText!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class _DashboardEventCard extends StatelessWidget {
  final EventModel event;
  final ThemeData theme;
  final VoidCallback onViewDetails;

  const _DashboardEventCard({required this.event, required this.theme, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    const isPublished = true; // Assumed
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(event.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Icon(Icons.more_vert, size: 20, color: theme.hintColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(label: 'Published', color: Colors.green, isDark: isDark),
              const SizedBox(width: 8),
              _StatusChip(label: 'Free', color: Colors.blue, isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(DateFormat('MM/dd/yyyy').format(event.startTimeDt), style: theme.textTheme.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 14, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(event.location ?? 'Online', style: theme.textTheme.bodySmall),
            ],
          ),
           const SizedBox(height: 8),
           Row(
            children: [
              Icon(Icons.people, size: 14, color: theme.hintColor),
               const SizedBox(width: 4),
              Text('${event.registeredCount} attendees', style: theme.textTheme.bodySmall),
            ],
           ),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               onPressed: onViewDetails,
               style: ElevatedButton.styleFrom(
                 backgroundColor: theme.primaryColor,
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               child: const Text('View Details'),
             ),
           )
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final MaterialColor color;
  final bool isDark;

  const _StatusChip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Detailed Analytics View (Right side of the dashboard in screenshot)
class _EventAnalyticsDetailScreen extends StatelessWidget {
  final EventModel event;

  const _EventAnalyticsDetailScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Mock Data
    const views = 1234;
    const conversionRate = 18.4;
    const revenue = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: theme.hintColor),
                           const SizedBox(width: 4),
                          Text(DateFormat('MM/dd/yyyy').format(event.startTimeDt), style: theme.textTheme.bodySmall),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: theme.hintColor),
                           const SizedBox(width: 4),
                          Text(event.location ?? 'Online', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                 _StatusChip(label: 'Published', color: Colors.green, isDark: isDark),
              ],
            ),
            
            const SizedBox(height: 32),
            Text("Quick Stats", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _DetailStatCard(label: "Total Attendees", value: "${event.registeredCount}", theme: theme)),
                const SizedBox(width: 12),
                Expanded(child: _DetailStatCard(label: "Views", value: "$views", theme: theme)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                 Expanded(child: _DetailStatCard(label: "Registration Rate", value: "$conversionRate%", theme: theme)),
                const SizedBox(width: 12),
                 Expanded(child: _DetailStatCard(label: "Revenue", value: "\$$revenue", theme: theme)),
              ],
            ),

            const SizedBox(height: 32),
            
            // Ticketing Analytics Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                 borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ticketing Analytics", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text("\$0 / ticket", style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Ticket Sales Progress", style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("0 / 10 sold"), // Mock
                      Text("0%"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: 0.0, backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300], color: theme.primaryColor),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Free (Comps)", style: theme.textTheme.bodySmall),
                          Text("0", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Paid Sales", style: theme.textTheme.bodySmall),
                          Text("0", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailStatCard({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

