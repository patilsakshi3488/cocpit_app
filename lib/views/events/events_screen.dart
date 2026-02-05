import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_card.dart';
import 'event_details_screen.dart';
import 'create_event_screen.dart';
import 'event_dashboard_screen.dart';
import '../bottom_navigation.dart';
import '../../widgets/app_top_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // State
  // We use futures for each tab to manage loading states independently
  Future<List<EventModel>>? _discoverEvents;
  Future<List<EventModel>>? _registeredEvents;
  Future<List<EventModel>>? _savedEvents;
  Future<List<EventModel>>? _myEvents;

  // Filters
  bool fOnline = false;
  bool fInPerson = false;
  // bool fFree = false; // Backend doesn't support yet
  // bool fPaid = false; // Backend doesn't support yet
  // Map<String, bool> fCategories = ... // Backend doesn't support yet

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      // Refresh data on tab change to keep lists up to date (e.g. after registration)
      if (!_tabController.indexIsChanging) _refreshCurrentTab();
    });
    _loadAllData();
  }

  void _loadAllData() {
    setState(() {
      _discoverEvents = EventService.getEvents(
        startDate: DateTime.now().toIso8601String(),
      );
      _registeredEvents = EventService.getMyRegisteredEvents();
      _savedEvents = EventService.getMySavedEvents();
      _myEvents = EventService.getMyCreatedEvents();
    });
  }

  Future<void> _refreshCurrentTab() async {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _discoverEvents = EventService.getEvents(
            type: fOnline ? 'Online' : (fInPerson ? 'InPerson' : null),
            startDate: DateTime.now().toIso8601String(),
            // Pass other filters if backend supported them
          );
          break;
        case 1:
          _registeredEvents = EventService.getMyRegisteredEvents();
          break;
        case 2:
          _savedEvents = EventService.getMySavedEvents();
          break;
        case 3:
          _myEvents = EventService.getMyCreatedEvents();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onEventTap(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          event: event,
          // We pass initial state, but screen will verify with API
          isRegistered: event.isRegistered,
          isSaved: event.isSaved,
          onSaveToggle: (saved) {
            // Optimistic update in list?
            // Since we use FutureBuilder, we might need to manually update the list inside the future,
            // or just refresh the tab when coming back.
          },
          onRegister: () {},
          onCancelRegistration: () {},
        ),
      ),
    );
    // Refresh to reflect changes (registration count, status)
    _refreshCurrentTab();
  }

  void _openFilterSheet() {
    bool tOnline = fOnline;
    bool tInPerson = fInPerson;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSS) => DraggableScrollableSheet(
          initialChildSize: 0.4, // Reduced size since fewer filters
          maxChildSize: 0.6,
          minChildSize: 0.3,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      Text(
                        'Filters',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _fSection(theme, 'Event Type'),
                      _fItem(
                        theme,
                        'Online',
                        tOnline,
                        (v) => setSS(() => tOnline = v),
                      ),
                      _fItem(
                        theme,
                        'In-person',
                        tInPerson,
                        (v) => setSS(() => tInPerson = v),
                      ),
                      // Backend doesn't support Price/Category filters yet
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSS(() {
                              tOnline = false;
                              tInPerson = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              fOnline = tOnline;
                              fInPerson = tInPerson;
                            });
                            Navigator.pop(context);
                            // Apply filters
                            _discoverEvents = EventService.getEvents(
                              type: fOnline
                                  ? 'Online'
                                  : (fInPerson ? 'InPerson' : null),
                              startDate: DateTime.now().toIso8601String(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fSection(ThemeData theme, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
  Widget _fItem(ThemeData theme, String l, bool s, Function(bool) onTap) =>
      GestureDetector(
        onTap: () => onTap(!s),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: s ? theme.primaryColor : theme.dividerColor,
                    width: 2,
                  ),
                  color: s ? theme.primaryColor : Colors.transparent,
                ),
                child: s
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Text(l, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppTopBar(
        searchType: SearchType.events,
        controller: _searchCtrl,
        onChanged: (v) => setState(
          () {},
        ), // Local search filtering on top of fetched results? Or API search?
        // Backend doesn't have search query param, only filters.
        // We will filter client-side for now on the fetched list.
        onFilterTap: _openFilterSheet,
      ),
      body: Column(
        // Changed to Column to allow TabBar to be fixed or sticky if needed, but keeping original structure
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          _buildTabs(theme),
          Expanded(child: _buildActiveTabContent(theme)),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_createEventButton(theme)],
      ),
    );
  }

  Widget _createEventButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (res != null) {
            _loadAllData(); // Refresh all as we might have created an event
          }
        },
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 14),
        label: Text(
          'Create Event',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: theme.primaryColor,
      indicatorWeight: 3,
      labelColor: theme.primaryColor,
      unselectedLabelColor: theme.textTheme.bodySmall?.color,
      dividerColor: theme.dividerColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(text: 'Discover'),
        Tab(text: 'Registered'),
        Tab(text: 'Saved'),
        Tab(text: 'My Events'),
        Tab(text: 'Event Dashboard'),
      ],
    );
  }

  Widget _buildActiveTabContent(ThemeData theme) {
    Future<List<EventModel>>? targetFuture;
    switch (_tabController.index) {
      case 0:
        targetFuture = _discoverEvents;
        break;
      case 1:
        targetFuture = _registeredEvents;
        break;
      case 2:
        targetFuture = _savedEvents;
        break;
      case 3:
        targetFuture = _myEvents;
        break;
      case 4:
         return const EventDashboardScreen();
    }

    return FutureBuilder<List<EventModel>>(
      future: targetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        List<EventModel> events = snapshot.data ?? [];

        // Client side filtering for search text
        if (_searchCtrl.text.isNotEmpty) {
          final query = _searchCtrl.text.toLowerCase();
          events = events
              .where(
                (e) =>
                    e.title.toLowerCase().contains(query) ||
                    e.description.toLowerCase().contains(query),
              )
              .toList();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tabController.index == 0 && events.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Text(
                    'Suggested for you',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildSuggestedSection(theme, events),
              ],
              const SizedBox(height: 24),
              _evList(theme, events, isMy: _tabController.index == 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestedSection(ThemeData theme, List<EventModel> allEvents) {
    // Show top 5 events as suggested for now
    final suggested = allEvents.take(5).toList();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: suggested.length,
        itemBuilder: (context, index) =>
            _suggestedCard(theme, suggested[index]),
      ),
    );
  }

  Widget _suggestedCard(ThemeData theme, EventModel event) {
    final colorScheme = theme.colorScheme;

    ImageProvider imgProv;
    if (event.image.startsWith('http')) {
      imgProv = NetworkImage(event.image);
    } else {
      imgProv = AssetImage(event.image);
    }

    return GestureDetector(
      onTap: () => _onEventTap(event),
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: imgProv,
            fit: BoxFit.cover,
            onError: (e, s) {
              // Fallback if image fails?
            },
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // Backend doesn't support price yet, defaulting to free
              // if (!event.isFree) ...
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location ?? 'Online',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _evList(
    ThemeData theme,
    List<EventModel> events, {
    bool isMy = false,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Text(
            'No events found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: events.length,
      itemBuilder: (context, i) => EventCard(
        event: events[i],
        isMyEvent: isMy || events[i].createdByMe,
        isRegistered: events[i].isRegistered,
        isSaved: events[i].isSaved,
        onSaveToggle: () async {
          // We handle save toggle here by calling API and refreshing?
          // Or better, let EventCard handle UI and we just call API
          if (events[i].isSaved) {
            await EventService.unsaveEvent(events[i].id);
          } else {
            await EventService.saveEvent(events[i].id);
          }
          _refreshCurrentTab();
        },
        onTap: () => _onEventTap(events[i]),
        onEdit: () => _handleEdit(events[i]),
        onDelete: () => _handleDelete(events[i]),
      ),
    );
  }

  void _handleEdit(EventModel event) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(event: event),
      ),
    );
    if (res != null) {
      _loadAllData();
    }
  }

  void _handleDelete(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
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
        await EventService.deleteEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
    }
  }
}
