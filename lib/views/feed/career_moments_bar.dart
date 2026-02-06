import 'package:flutter/material.dart';
import 'create_career_moment_screen.dart';
import 'career_moment_viewer.dart';

class CareerMomentsBar extends StatelessWidget {
  final List<Map<String, dynamic>> careerMoments;
  const CareerMomentsBar({super.key, required this.careerMoments});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth > 600 ? 150 : 120;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: careerMoments.length,
        itemBuilder: (context, index) {
          final m = careerMoments[index];
          return GestureDetector(
            onTap: () {
              if (m['isMine']) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCareerMomentScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CareerMomentViewer(users: careerMoments, initialUserIndex: index)));
              }
            },
            child: Container(
              width: itemWidth,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: !m['isMine'] ? DecorationImage(image: AssetImage(m['image']), fit: BoxFit.cover) : null,
                color: m['isMine'] ? const Color(0xFF4F70F0) : const Color(0xFF1F2937),
              ),
              child: Stack(
                children: [
                  if (m['isMine'])
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 12),
                          const Text("Your Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  if (!m['isMine'])
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Column(
                        children: [
                          CircleAvatar(radius: 18, backgroundColor: const Color(0xFF7C83FF), child: CircleAvatar(radius: 16, backgroundImage: AssetImage(m['profile']))),
                          const SizedBox(height: 4),
                          Text(m['name'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

