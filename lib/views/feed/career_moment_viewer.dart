import 'package:flutter/material.dart';

class CareerMomentViewer extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final int initialUserIndex;

  const CareerMomentViewer({
    super.key,
    required this.users,
    required this.initialUserIndex,
  });

  @override
  State<CareerMomentViewer> createState() => _CareerMomentViewerState();
}

class _CareerMomentViewerState extends State<CareerMomentViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late List<_StoryItem> _flatStories;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _flatStories = [];
    int initialPage = 0;

    for (int i = 0; i < widget.users.length; i++) {
      final user = widget.users[i];
      final stories = user['stories'] as List;
      if (i == widget.initialUserIndex) initialPage = _flatStories.length;

      for (int j = 0; j < stories.length; j++) {
        _flatStories.add(
          _StoryItem(
            userIndex: i,
            storyIndex: j,
            user: user,
            story: stories[j],
          ),
        );
      }
    }

    _currentIndex = initialPage;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _nextStory();
    });

    _startStory();
  }

  void _startStory() {
    _animController.stop();
    _animController.reset();
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < _flatStories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_flatStories.isEmpty)
      return const Scaffold(backgroundColor: Colors.black);

    final current = _flatStories[_currentIndex];
    final userStories = current.user['stories'] as List;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) Navigator.pop(context);
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _flatStories.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
                _startStory();
              },
              itemBuilder: (context, idx) {
                return Image.asset(
                  _flatStories[idx].story['image'],
                  fit: BoxFit.cover,
                );
              },
            ),
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(userStories.length, (idx) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          double val = 0.0;
                          if (idx < current.storyIndex) {
                            val = 1.0;
                          } else if (idx == current.storyIndex) {
                            val = _animController.value;
                          }
                          return LinearProgressIndicator(
                            value: val,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 70,
              left: 20,
              right: 10,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(current.user['profile'] ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    current.user['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    current.story['time'] ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Text(
                current.story['text'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _prevStory,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextStory,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryItem {
  final int userIndex;
  final int storyIndex;
  final Map<String, dynamic> user;
  final Map<String, dynamic> story;
  _StoryItem({
    required this.userIndex,
    required this.storyIndex,
    required this.user,
    required this.story,
  });
}
