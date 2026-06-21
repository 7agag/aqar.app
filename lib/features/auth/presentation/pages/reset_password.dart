import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aqar_button.dart';
import '../../../../core/widgets/aqar_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _hasToken => widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasToken) {
      context.read<AuthBloc>().add(
        VerifyResetTokenRequested(token: widget.token!),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully. Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        }
        if (state is AuthResetTokenInvalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isVerifying = isLoading && _hasToken;
        final showForm = state is AuthResetTokenVerified || isLoading && !isVerifying;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (_) => false,
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isVerifying
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _hasToken && showForm
                      ? _buildResetForm(isLoading)
                      : const _InvalidResetLink(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResetForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.password_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a new password for your AQAR account.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          AqarTextField(
            label: 'New Password',
            hint: 'At least 8 characters',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.textHint,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your new password';
              if (v.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AqarTextField(
            label: 'Confirm Password',
            hint: 'Repeat your new password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.textHint,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          AqarButton(
            text: 'Reset Password',
            isLoading: isLoading,
            suffix: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(
                      ResetPasswordRequested(
                        token: widget.token!,
                        newPassword: _passwordController.text,
                      ),
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InvalidResetLink extends StatelessWidget {
  const _InvalidResetLink();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.link_off_rounded,
            size: 44,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Invalid Reset Link',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please request a new password reset link from the login screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        AqarButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (_) => false,
          ),
        ),
      ],
    );
  }
}
