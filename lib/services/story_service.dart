import 'dart:convert';
import 'package:cocpit_app/config/api_config.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/api_client.dart';

class StoryService {
  static Future<List<StoryGroup>> getGroupedStories() async {
    final response = await ApiClient.get(ApiConfig.storiesGrouped);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StoryGroup.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load stories");
    }
  }

  static Future<void> createStory({
    required String title,
    required String description,
    required String mediaUrl,
    // required String mediaType
  }) async {
    final response = await ApiClient.post(
      ApiConfig.story,
      body: {
        "title": title,
        "description": description,
        "media_url": mediaUrl,
        // "media_type":mediaType
      },
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create story");
    }
  }

  static Future<void> deleteStory(String storyId) async {
    final response = await ApiClient.delete("${ApiConfig.stories}/$storyId");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete story");
    }
  }

  static Future<void> viewStory(String storyId) async {
    final response = await ApiClient.post(
      "${ApiConfig.stories}/$storyId/view",
    );

    // 200 OK
    if (response.statusCode != 200) {
      // It might return 404 or other, but usually we just ignore errors for view tracking or log them
      print("Failed to record view for story $storyId: ${response.statusCode}");
    }
  }

  static Future<bool> reactToStory(String storyId, String reaction) async {
    final response = await ApiClient.post(
      "${ApiConfig.stories}/$storyId/react",
      body: {"reaction": reaction},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Backend returns { is_liked: boolean, ... }
      return body['is_liked'] ?? false;
    } else {
      throw Exception("Failed to react to story");
    }
  }

  static Future<Map<String, dynamic>> getStoryDetails(String storyId) async {
    final response = await ApiClient.get("${ApiConfig.stories}/$storyId");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get story details");
    }
  }
}


//
//
//
// import 'dart:convert';
// import 'package:cocpit_app/config/api_config.dart';
// import 'package:cocpit_app/models/story_model.dart';
// import 'package:cocpit_app/services/api_client.dart';
//
// class StoryService {
//   static Future<List<StoryGroup>> getGroupedStories() async {
//     final response = await ApiClient.get(ApiConfig.storiesGrouped);
//
//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((json) => StoryGroup.fromJson(json)).toList();
//     } else {
//       throw Exception("Failed to load stories");
//     }
//   }
//
//   static Future<void> createStory({
//     required String title,
//     required String description,
//     required String mediaUrl,
//   }) async {
//     final response = await ApiClient.post(
//       ApiConfig.story,
//       body: {
//         "title": title,
//         "description": description,
//         "media_url": mediaUrl,
//       },
//     );
//
//     if (response.statusCode != 201) {
//       throw Exception("Failed to create story");
//     }
//   }
//
//   static Future<void> deleteStory(String storyId) async {
//     final response = await ApiClient.delete("${ApiConfig.stories}/$storyId");
//
//     if (response.statusCode != 200) {
//       throw Exception("Failed to delete story");
//     }
//   }
//
//   static Future<void> viewStory(String storyId) async {
//     final response = await ApiClient.post(
//       "${ApiConfig.stories}/$storyId/view",
//     );
//
//     // 200 OK
//     if (response.statusCode != 200) {
//       // It might return 404 or other, but usually we just ignore errors for view tracking or log them
//       print("Failed to record view for story $storyId: ${response.statusCode}");
//     }
//   }
//
//   static Future<bool> reactToStory(String storyId, String reaction) async {
//     final response = await ApiClient.post(
//       "${ApiConfig.stories}/$storyId/react",
//       body: {"reaction": reaction},
//     );
//
//     if (response.statusCode == 200) {
//       final body = jsonDecode(response.body);
//       // Backend returns { is_liked: boolean, ... }
//       return body['is_liked'] ?? false;
//     } else {
//       throw Exception("Failed to react to story");
//     }
//   }
//
//   static Future<Map<String, dynamic>> getStoryDetails(String storyId) async {
//     final response = await ApiClient.get("${ApiConfig.stories}/$storyId");
//
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception("Failed to get story details");
//     }
//   }
// }
