import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aqar/core/theme/app_colors.dart';

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  int? _expandedIndex;

  static const _faqs = [
    _FaqItem(
      question: 'How do I create an account?',
      answer: 'Tap "Sign Up" on the login screen, enter your name, email, and password. '
          'You\'ll receive an OTP via email to verify your account.',
    ),
    _FaqItem(
      question: 'How do I list a property?',
      answer: 'Go to your Profile, tap "My Property", then "Add Property". '
          'Follow the stepper to add property details, images, and ownership proof. '
          'Your listing will be reviewed by admins before going live.',
    ),
    _FaqItem(
      question: 'How do I send a rent request?',
      answer: 'Open a property listing and tap "Request Rent". '
          'Choose your desired dates and submit. The owner will review and respond.',
    ),
    _FaqItem(
      question: 'How do I chat with an owner?',
      answer: 'On a property listing, tap "Contact Owner" to start a chat. '
          'You can also access all your chats from the Profile page under "My Chats".',
    ),
    _FaqItem(
      question: 'How do payments work?',
      answer: 'Once a rent request is accepted, you can pay securely through the app. '
          'We support credit/debit cards, Fawry, Instapay, and mobile wallets. '
          'Your payment is processed through Kashier payment gateway.',
    ),
    _FaqItem(
      question: 'How do I view my invoices?',
      answer: 'Go to your Profile and tap "Invoices" to view all your invoices. '
          'You can see paid, pending, and overdue invoices with full details.',
    ),
    _FaqItem(
      question: 'How do I reset my password?',
      answer: 'On the login screen, tap "Forgot Password". Enter your email address '
          'and you\'ll receive a password reset link.',
    ),
    _FaqItem(
      question: 'How do I mark a property as sold?',
      answer: 'Go to "My Property" from your Profile, open the property details, '
          'and tap "Mark as Sold". This will update the listing status.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Browse through frequently asked questions\nor contact our support team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ..._faqs.asMap().entries.map((entry) => _buildFaqTile(entry.key, entry.value)),
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFaqTile(int index, _FaqItem faq) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is ready to assist you.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.email_outlined, size: 20),
              label: const Text(
                'Contact Support',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _contactSupport(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:support@aqar.com?subject=${Uri.encodeComponent('AQAR Support Request')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }
}
