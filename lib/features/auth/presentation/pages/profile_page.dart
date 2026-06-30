import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import '../../../../core/network/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../property/presentation/bloc/property_bloc.dart';
import '../../../property/presentation/bloc/property_event.dart';
import '../../../property/presentation/bloc/property_state.dart';
import '../../../property/presentation/widgets/profile_properties_widget.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import 'profile_info_page.dart';
import 'package:aqar/features/lease/presentation/pages/lease_list_page.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_requests_page.dart';
import 'package:aqar/features/payment/presentation/pages/invoices_page.dart';
import 'package:aqar/features/payment/presentation/pages/wallet_page.dart';
import 'package:aqar/features/chat/presentation/pages/chat_list_page.dart';
import 'package:aqar/features/settings/presentation/pages/settings_page.dart';
import 'package:aqar/injection_container.dart' as di;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool _profileRequested = false;
  bool _isRefreshing = false;
  bool _socketConnected = false;
  String? _profileError;
  StreamSubscription<bool>? _socketSub;
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckAuthStatus());
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _socketConnected = di.sl<SocketService>().isConnected;
    _socketSub = di.sl<SocketService>().onConnectionChange.listen((connected) {
      if (mounted) setState(() => _socketConnected = connected);
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginSuccess && !_profileRequested) {
            _profileRequested = true;
            _profileError = null;
            context.read<AuthBloc>().add(GetProfileRequested());
          }
          if (state is AuthProfileLoaded) {
            _staggerCtrl.forward();
            _profileError = null;
            context.read<PropertyBloc>().add(const GetMyPropertiesRequested());
          }
          if (state is AuthUnauthenticated || state is AuthInitial) {
            _profileRequested = false;
            _profileError = null;
          }
          if (state is AuthError) {
            _profileRequested = false;
            _profileError = state.message;
          }
        },
        builder: (context, state) {
          if (state is AuthLoading || state is AuthProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AuthProfileLoaded) {
            return _buildProfileContent(context, state.user);
          }
          if (state is AuthLoginSuccess) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AuthUnauthenticated || state is AuthInitial) {
            return _buildNotLoggedInView(context);
          }
          if (state is AuthError) {
            return _buildNotLoggedInView(context, errorMessage: _profileError);
          }
          return _buildNotLoggedInView(context);
        },
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context, {String? errorMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline_rounded, size: 44, color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to AQAR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in or create an account\nto manage your listings & requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Login / Sign Up',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserEntity user) {
    final userName = user.fullName.isNotEmpty ? user.fullName : 'AQAR User';
    final userEmail = user.email;
    final statusText = user.isVerified ? 'Verified account' : 'Not verified';
    final statusColor =
        user.isVerified ? const Color(0xFF2E7D32) : AppColors.textSecondary;

    return RefreshIndicator(
      onRefresh: () async {
        if (_isRefreshing) return;
        _isRefreshing = true;
        context.read<AuthBloc>().add(GetProfileRequested());
        await context.read<AuthBloc>().stream.firstWhere(
          (s) => s is AuthProfileLoaded || s is AuthError,
        );
        if (mounted) _isRefreshing = false;
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildGradientHeader(user, userName, userEmail, statusText, statusColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuRow(
                    Icons.person_outline,
                    'Profile Information',
                    userEmail.isNotEmpty ? userEmail : 'No email available',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileInfoPage()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: AppColors.borderLight.withValues(alpha: 0.5), height: 1),
                  const SizedBox(height: AppSpacing.md),
                  BlocProvider.value(
                    value: di.sl<PropertyBloc>(),
                    child: const ProfilePropertiesWidget(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: AppColors.borderLight.withValues(alpha: 0.5), height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMenuRow(
                    Icons.inbox_outlined,
                    'My Request',
                    'Rent & purchase requests',
                    () => _navigateIfAuthenticated(
                      context,
                      const MyRequestsPage(),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.description_outlined,
                    'My Leases',
                    'View your active & past leases',
                    () => _navigateIfAuthenticated(
                      context,
                      const LeaseListPage(),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.receipt_outlined,
                    'Invoices',
                    'View your invoices',
                    () => _navigateIfAuthenticated(
                      context,
                      const InvoicesPage(),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.wallet_outlined,
                    'Wallet',
                    'View your wallet & transactions',
                    () => _navigateIfAuthenticated(
                      context,
                      const WalletPage(),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.chat_outlined,
                    'My Chats',
                    'Messages with owners & tenants',
                    () => _navigateIfAuthenticated(
                      context,
                      const ChatListPage(),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.settings_outlined,
                    'Settings',
                    'Language, notifications & more',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                  _buildMenuRow(
                    Icons.mail_outline,
                    'Contact Us',
                    'Send us an email',
                    () => _contactUs(context, user),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLogoutButton(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateIfAuthenticated(BuildContext context, Widget page) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthProfileLoaded) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Widget _buildGradientHeader(
    UserEntity user,
    String userName,
    String userEmail,
    String statusText,
    Color statusColor,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceLight,
                  child: Text(
                    _getInitials(user),
                    style: const TextStyle(
                      fontSize: 40,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileInfoPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                user.isVerified ? Icons.verified_outlined : Icons.info_outline,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                statusText,
                style: TextStyle(fontSize: 13, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            userEmail,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const SizedBox(width: AppSpacing.lg),
              BlocBuilder<PropertyBloc, PropertyState>(
                builder: (context, pState) {
                  final count = pState is MyPropertiesLoaded ? pState.properties.length : user.propertiesCount;
                  return Expanded(child: _buildStatCard('$count', 'LISTINGS'));
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildStatCard('${user.favoritesCount}', 'FAVORITES')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildStatusCard()),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final connected = _socketConnected;
    final dotColor = connected ? const Color(0xFF2ECC71) : AppColors.textHint;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, anim, _) {
        final pulse = connected ? (0.7 + 0.3 * (1 - anim)) : 1.0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connected ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: connected ? const Color(0xFF2ECC71) : AppColors.textHint,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: connected
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.6)
                      : AppColors.textHint.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String number, String label, {Color? numberColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.tryParse(number) ?? 0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              number.contains(RegExp(r'[A-Za-z]')) ? number : value.toInt().toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: numberColor ?? AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _confirmLogout(context),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getInitials(UserEntity user) {
    final f = user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '';
    final s = user.secondName.isNotEmpty ? user.secondName[0].toUpperCase() : '';
    return '$f$s';
  }

  Future<void> _contactUs(BuildContext context, UserEntity user) async {
    String body = '';

    if (user.fullName.isNotEmpty) {
      body += 'User: ${user.fullName}\n';
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = await deviceInfo.deviceInfo;
      if (info is AndroidDeviceInfo) {
        body += 'Device: ${info.brand} ${info.model}\n';
        body += 'OS: Android ${info.version.release}';
      } else if (info is IosDeviceInfo) {
        body += 'Device: ${info.model}\n';
        body += 'OS: iOS ${info.systemVersion}';
      } else if (info is WindowsDeviceInfo) {
        body += 'Device: Windows ${info.computerName}\n';
        body += 'OS: ${info.productName} ${info.majorVersion}.${info.minorVersion}';
      } else if (info is LinuxDeviceInfo) {
        body += 'Device: Linux\n';
        body += 'OS: ${info.prettyName}';
      } else if (info is MacOsDeviceInfo) {
        body += 'Device: macOS\n';
        body += 'OS: ${info.computerName} ${info.osRelease}';
      }
    } catch (_) {
      body += 'Device info unavailable';
    }

    final uri = Uri.parse(
      'mailto:mhmmsrhan@gmail.com?subject=${Uri.encodeComponent('aqar problem')}&body=${Uri.encodeComponent(body)}',
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
