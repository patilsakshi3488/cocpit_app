import 'package:flutter/material.dart';

import 'widgets/contact_info_modal.dart';

class ProfileInfoIdentity extends StatelessWidget {
  final String name;
  final String headline;
  final String location;
  final String openTo;
  final String availability;
  final String preference;
  final VoidCallback onEditProfile;
  final VoidCallback onEditIdentity;
  final bool isReadOnly;
  final VoidCallback? onMessage;
  final VoidCallback? onFollow;
  final int connectionCount;
  final String? latestEducation;
  final bool isFollowing;
  
  // New Contact Fields
  final String? email;
  final String? mobileNumber;
  final String? profileUrl;

  const ProfileInfoIdentity({
    super.key,
    required this.name,
    required this.headline,
    required this.location,
    required this.openTo,
    required this.availability,
    required this.preference,
    required this.onEditProfile,
    required this.onEditIdentity,
    this.isReadOnly = false,
    this.onMessage,
    this.onFollow,
    required this.connectionCount,
    this.latestEducation,
    this.isFollowing = false,
    this.email,
    this.mobileNumber,
    this.profileUrl,
  });

  void _showContactInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (ctx) => ContactInfoModal(
        userName: name,
        email: email,
        phone: mobileNumber,
        profileUrl: profileUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.verified, color: theme.primaryColor, size: 20),
              const Spacer(),
              if (!isReadOnly)
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.iconTheme.color?.withValues(alpha: 0.5),
                    size: 28,
                  ),
                  onPressed: onEditProfile,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),

          if (latestEducation != null && latestEducation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    latestEducation!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Wrap(
            children: [
              Text(
                "$location  •  ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              GestureDetector(
                onTap: () => _showContactInfo(context),
                child: Text(
                  "Contact info",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$connectionCount connections",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          if (isReadOnly) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? theme.cardColor
                          : theme.primaryColor,
                      foregroundColor: isFollowing
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.white,
                      side: isFollowing
                          ? BorderSide(color: theme.dividerColor)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isFollowing ? "Following" : "Follow",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMessage,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.primaryColor),
                      foregroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Message",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          GestureDetector(
            onTap: isReadOnly ? null : onEditIdentity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _identityRow(
                  context,
                  "OPEN TO:",
                  openTo,
                  colorScheme.surfaceContainer,
                  theme.primaryColor,
                ),
                const SizedBox(height: 8),
                _identityRow(
                  context,
                  "AVAILABILITY:",
                  availability,
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _identityRow(
                  context,
                  "PREFERENCE:",
                  preference,
                  colorScheme.surfaceContainer,
                  theme.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _identityRow(
    BuildContext context,
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.dividerColor),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label ",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
