import 'package:aqar/features/auth/presentation/pages/otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aqar_button.dart';
import '../../../../core/widgets/aqar_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthBloc>(),
                child: OtpPage(email: state.email),
              ),
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
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name + Last Name جنب بعض
              Row(
                children: [
                  Expanded(
                    child: AqarTextField(
                      label: 'First Name',
                      hint: 'Jane',
                      controller: _firstNameController,
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AqarTextField(
                      label: 'Last Name',
                      hint: 'Doe',
                      controller: _lastNameController,
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Email
              AqarTextField(
                label: 'Email Address',
                hint: 'hello@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Password
              AqarTextField(
                label: "Password",
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password';
                  if (v.length < 8) return 'At least 8 characters';
                  return null;
                },
              ),

              SizedBox(height: 20),

              // Confirm Password
              AqarTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
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

              // Create Account Button
              AqarButton(
                text: 'Create Account',
                isLoading: state is AuthLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                          RegisterRequested(
                            firstName: _firstNameController.text.trim(),
                            secondName: _lastNameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                            confirmPassword: _confirmPasswordController.text,
                          ),
                        );
                  }
                },
              ),

              SizedBox(height: 28),

              // Terms
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'By creating an account, you agree to our '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
