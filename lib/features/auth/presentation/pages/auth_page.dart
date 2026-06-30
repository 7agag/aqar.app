import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Logo
              Image.asset(
                'assets/icons/aqar.png',
                height: 80,
              ),
              SizedBox(height: 12),

              // Subtitle
              Text(
                _isSignIn
                    ? 'Welcome back to the modern estate.'
                    : 'Create your exclusive account.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Toggle
              _buildToggle(),

              const SizedBox(height: 32),

              // Page content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSignIn
                    ? LoginPage(key: const ValueKey('login'))
                    : RegisterPage(key: const ValueKey('register')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _toggleTab(
              'Sign In', _isSignIn, () => setState(() => _isSignIn = true)),
          _toggleTab(
              'Register', !_isSignIn, () => setState(() => _isSignIn = false)),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
