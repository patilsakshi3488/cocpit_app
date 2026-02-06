class MessageTransformer {
  /// Transforms raw system message data into user-friendly text.
  /// Matches website (frontend-only) transformation logic.
  static String getSystemText(
    Map<String, dynamic> msg,
    String? myUserId, {
    String? myUserName,
  }) {
    final actionType = msg['action_type'];
    final senderId = msg['sender_id']?.toString();
    final targetId = msg['target_id']?.toString();
    final senderName = msg['sender_name'] ?? 'Someone';
    final targetName = msg['target_name'] ?? 'Someone';

    // Check if sender is me by ID or by name (fallback)
    final isMeSender =
        senderId == myUserId ||
        senderId == 'me' ||
        (myUserName != null &&
            senderName.toLowerCase() == myUserName.toLowerCase());

    // Check if target is me by ID or by name (fallback)
    final isMeTarget =
        targetId == myUserId ||
        targetId == 'me' ||
        (myUserName != null &&
            targetName.toLowerCase() == myUserName.toLowerCase());

    switch (actionType) {
      case 'create_group':
        return isMeSender
            ? "You created the group"
            : "$senderName created the group";
      case 'add':
        if (isMeTarget) return "You were added";
        return "$targetName was added";
      case 'leave':
        return isMeSender ? "You left the group" : "$senderName left the group";
      case 'remove':
        if (isMeTarget) return "You were removed";
        return "$targetName was removed";
      case 'update_avatar':
        return isMeSender
            ? "You updated group icon"
            : "$senderName updated group icon";
      default:
        // Fallback to text_content if provided, otherwise generic
        return msg['text_content'] ?? 'System Message';
    }
  }
}
