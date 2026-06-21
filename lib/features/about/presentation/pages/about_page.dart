import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aqar/core/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'About AQAR',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AQAR',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Trusted Real Estate Platform',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'AQAR is a real estate marketplace that connects property owners, renters, and buyers. '
                    'We provide a seamless platform for listing, discovering, and managing rental and sale '
                    'properties with verified listings and direct communication.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Features include property browsing with advanced filters, favorites & comparison, '
                    'real-time chat with owners, rental request management, invoice tracking, '
                    'secure payments, and a digital wallet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLinkTile(
              Icons.description_outlined,
              'Privacy Policy',
              () => _launchUrl('https://aqar.com/privacy'),
            ),
            const SizedBox(height: 2),
            _buildLinkTile(
              Icons.gavel_outlined,
              'Terms of Service',
              () => _launchUrl('https://aqar.com/terms'),
            ),
            const SizedBox(height: 2),
            _buildLinkTile(
              Icons.build_outlined,
              'Open Source Licenses',
              () => showLicensePage(
                context: context,
                applicationName: 'AQAR',
                applicationVersion: '1.0.0',
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Made with \u2665 by Team AQAR',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u00A9 2026 AQAR. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
