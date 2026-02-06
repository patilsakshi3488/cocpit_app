import 'package:flutter/material.dart';

class DemographicsSection extends StatelessWidget {
  final Color primary;
  final Color textColor;

  const DemographicsSection({
    super.key,
    required this.primary,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDemographicItem("Top Job Titles", [
          {"label": "Product Manager", "value": "24%"},
          {"label": "Software Engineer", "value": "18%"},
          {"label": "UX Designer", "value": "15%"},
        ]),
        const SizedBox(height: 24),
        _buildDemographicItem("Top Companies", [
          {"label": "Google", "value": "12%"},
          {"label": "Meta", "style": const TextStyle(fontWeight: FontWeight.bold)},
          {"label": "Amazon", "value": "8%"},
          {"label": "Apple", "value": "5%"},
        ]),
        const SizedBox(height: 24),
        _buildDemographicItem("Top Locations", [
          {"label": "San Francisco Bay Area", "value": "32%"},
          {"label": "Greater New York City Area", "value": "15%"},
          {"label": "Greater Seattle Area", "value": "10%"},
        ]),
      ],
    );
  }

  Widget _buildDemographicItem(String title, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item["label"] as String,
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 14),
                ),
                Text(
                  item["value"]?.toString() ?? "",
                  style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

