import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Contact Section
          _buildSectionHeader('Contact Us'),
          _buildContactTile(
            context: context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@betacaller.com',
            onTap: () => _launchEmail('support@betacaller.com'),
          ),
          _buildContactTile(
            context: context,
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: '+1 (555) 123-4567',
            onTap: () => _launchPhone('+15551234567'),
          ),
          _buildContactTile(
            context: context,
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live chat coming soon!'),
                ),
              );
            },
          ),
          const Divider(height: 1),

          const SizedBox(height: 16),

          // FAQs Section
          _buildSectionHeader('Frequently Asked Questions'),
          _buildFAQExpansionTile(
            question: 'How do I add balance to my account?',
            answer: 'You can add balance by going to your Profile tab and tapping on the "Add Balance" button. Choose your preferred payment method and enter the amount you want to add.',
          ),
          _buildFAQExpansionTile(
            question: 'What are the calling rates?',
            answer: 'Calling rates vary by destination country. You can check our rates page in the app or on our website. Most international calls start at \$0.02 per minute.',
          ),
          _buildFAQExpansionTile(
            question: 'How do I make a call?',
            answer: 'Go to the Dialpad tab, enter the phone number including country code, and tap the call button. Make sure you have sufficient balance in your account.',
          ),
          _buildFAQExpansionTile(
            question: 'Can I use the app without internet?',
            answer: 'No, BetaCaller requires an active internet connection (WiFi or mobile data) to make VoIP calls. A stable connection ensures better call quality.',
          ),
          _buildFAQExpansionTile(
            question: 'How do I view my call history?',
            answer: 'Your call history is available in the Recents tab. You can see all your past calls with details like duration, cost, and date.',
          ),
          _buildFAQExpansionTile(
            question: 'Is my payment information secure?',
            answer: 'Yes, we use industry-standard encryption and secure payment gateways to protect your payment information. We never store your full credit card details.',
          ),
          _buildFAQExpansionTile(
            question: 'How do I get a refund?',
            answer: 'If you need a refund, please contact our support team at support@betacaller.com with your transaction details. Refunds are processed within 5-7 business days.',
          ),
          const Divider(height: 1),

          const SizedBox(height: 16),

          // Resources Section
          _buildSectionHeader('Resources'),
          _buildResourceTile(
            context: context,
            icon: Icons.book_outlined,
            title: 'User Guide',
            subtitle: 'Learn how to use BetaCaller',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User guide coming soon!'),
                ),
              );
            },
          ),
          _buildResourceTile(
            context: context,
            icon: Icons.video_library_outlined,
            title: 'Video Tutorials',
            subtitle: 'Watch helpful video guides',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video tutorials coming soon!'),
                ),
              );
            },
          ),
          _buildResourceTile(
            context: context,
            icon: Icons.public,
            title: 'Visit Our Website',
            subtitle: 'www.betacaller.com',
            onTap: () => _launchURL('https://www.betacaller.com'),
          ),
          const Divider(height: 1),

          const SizedBox(height: 16),

          // Feedback Section
          _buildSectionHeader('Feedback'),
          _buildResourceTile(
            context: context,
            icon: Icons.star_outline,
            title: 'Rate Us',
            subtitle: 'Rate BetaCaller on the App Store',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App Store rating coming soon!'),
                ),
              );
            },
          ),
          _buildResourceTile(
            context: context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: () => _showFeedbackDialog(context),
          ),
          _buildResourceTile(
            context: context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () => _showBugReportDialog(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildResourceTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildFAQExpansionTile({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=BetaCaller Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We\'d love to hear your thoughts!'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send feedback to backend
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController bugController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the bug you encountered:'),
            const SizedBox(height: 16),
            TextField(
              controller: bugController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe the bug...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send bug report to backend
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report submitted. Thank you!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
