import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ContactInfoModal extends StatelessWidget {
  final String userName;
  final String? email;
  final String? phone;
  final String? profileUrl;

  const ContactInfoModal({
    super.key,
    required this.userName,
    this.email,
    this.phone,
    this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$userName's Contact Info",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Contact details provided by the user.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          if (email != null && email!.isNotEmpty)
            _buildContactItem(
              context,
              icon: Icons.email_outlined,
              label: "Email",
              value: email!,
              onTap: () => _launchEmail(email!),
            ),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildContactItem(
              context,
              icon: Icons.phone_outlined,
              label: "Phone",
              value: phone!,
              onTap: () => _launchPhone(phone!),
            ),
          ],
            if (profileUrl != null && profileUrl!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildContactItem(
              context,
              icon: Icons.link,
              label: "Profile URL",
              value: profileUrl!,
              onTap: () => _launchUrl(profileUrl!),
              isLink: true,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLink = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F3A),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isLink ? const Color(0xFF3B82F6) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email');
    try {
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (_) {}
  }

  void _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (_) {}
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // Fallback or Copy
        await Clipboard.setData(ClipboardData(text: url));
          // Since we can't show snackbar easily in async void without context if we don't pass if from call site, 
          // we'll assume it just works or fails silently.
          // Ideally we should pass context to show "Copied to clipboard" if launch fails.
      }
    } catch (_) {}
  }
}
