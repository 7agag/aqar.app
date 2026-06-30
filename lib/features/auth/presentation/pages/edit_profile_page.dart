import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameCtl;
  late final TextEditingController _secondNameCtl;
  late final TextEditingController _emailCtl;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final user = state is AuthProfileLoaded ? state.user : null;
    _firstNameCtl = TextEditingController(text: user?.firstName ?? '');
    _secondNameCtl = TextEditingController(text: user?.secondName ?? '');
    _emailCtl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _secondNameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  String _getInitials(String first, String second) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final s = second.isNotEmpty ? second[0].toUpperCase() : '';
    return '$f$s';
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameCtl.text.trim();
    final secondName = _secondNameCtl.text.trim();
    final email = _emailCtl.text.trim();

    context.read<AuthBloc>().add(UpdateProfileRequested(
      firstName: firstName.isNotEmpty ? firstName : null,
      secondName: secondName.isNotEmpty ? secondName : null,
      email: email.isNotEmpty ? email : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
        if (state is AuthError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          if (_firstNameCtl.text.isNotEmpty) _isSaving = true;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Edit Profile',
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
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        _getInitials(_firstNameCtl.text, _secondNameCtl.text),
                        style: const TextStyle(
                          fontSize: 36,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildField('First Name', _firstNameCtl),
                  const SizedBox(height: 16),
                  _buildField('Second Name', _secondNameCtl),
                  const SizedBox(height: 16),
                  _buildField('Email', _emailCtl,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Email is required' : null),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctl,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: ctl,
          validator: validator ??
              (v) => v == null || v.trim().isEmpty ? '$label is required' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
