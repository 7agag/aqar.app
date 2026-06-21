import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/injection_container.dart' as di;
import 'package:aqar/features/rent_request/presentation/pages/rent_request_detail_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';

class RentStatusBanner extends StatefulWidget {
  final int propertyId;

  const RentStatusBanner({super.key, required this.propertyId});

  @override
  State<RentStatusBanner> createState() => _RentStatusBannerState();
}

class _RentStatusBannerState extends State<RentStatusBanner>
    with SingleTickerProviderStateMixin {
  LocalLease? _lease;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _lease = di.sl<EscrowService>().getLeaseByProperty(widget.propertyId);
    di.sl<EscrowService>().addListener(_onEscrowChanged);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (_lease != null && _shouldPulse(_lease!)) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    di.sl<EscrowService>().removeListener(_onEscrowChanged);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onEscrowChanged() {
    if (!mounted) return;
    setState(() {
      _lease = di.sl<EscrowService>().getLeaseByProperty(widget.propertyId);
      if (_lease != null && _shouldPulse(_lease!)) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    });
  }

  bool _shouldPulse(LocalLease lease) {
    return lease.status == LeaseStatus.escrowActive &&
        lease.remaining.inHours < 24 &&
        !lease.isExpired;
  }

  @override
  Widget build(BuildContext context) {
    final lease = _lease;
    if (lease == null) return const SizedBox.shrink();
    return _BannerContent(
      pulseAnim: _pulseAnim,
      lease: lease,
      propertyId: widget.propertyId,
    );
  }
}

class _BannerContent extends StatelessWidget {
  final Animation<double> pulseAnim;
  final LocalLease lease;
  final int propertyId;

  const _BannerContent({
    required this.pulseAnim,
    required this.lease,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = lease.remaining;
    final isUrgent = lease.status == LeaseStatus.escrowActive &&
        remaining.inHours < 24 &&
        !lease.isExpired;

    BannerConfig config;
    switch (lease.status) {
      case LeaseStatus.awaitingPayment:
        config = BannerConfig(
          icon: Icons.hourglass_bottom_rounded,
          title: 'Awaiting Payment',
          subtitle: 'Owner will confirm shortly',
          colors: [const Color(0xFFFF8C00), const Color(0xFFFFB74D)],
          iconBg: const Color(0xFFFFF3E0),
        );
      case LeaseStatus.escrowActive:
        if (lease.isExpired) {
          config = BannerConfig(
            icon: Icons.timer_off_rounded,
            title: 'Payment Released',
            subtitle: '3-day period has ended',
            colors: [AppColors.success, const Color(0xFF66BB6A)],
            iconBg: const Color(0xFFE8F5E9),
          );
        } else {
          final days = remaining.inDays;
          final hours = remaining.inHours % 24;
          final timeText = days > 0 ? '${days}d ${hours}h' : '${hours}h';
          config = BannerConfig(
            icon: Icons.verified_rounded,
            title: 'Rented · $timeText left',
            subtitle: isUrgent ? 'Confirm receipt before time runs out' : 'Payment held in escrow',
            colors: isUrgent
                ? [const Color(0xFFE65100), const Color(0xFFFF8A65)]
                : [AppColors.success, const Color(0xFF66BB6A)],
            iconBg: isUrgent ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
          );
        }
      case LeaseStatus.tenantConfirmed:
        config = BannerConfig(
          icon: Icons.done_all_rounded,
          title: 'Receipt Confirmed',
          subtitle: 'Payment has been released to owner',
          colors: [AppColors.success, const Color(0xFF66BB6A)],
          iconBg: const Color(0xFFE8F5E9),
        );
      case LeaseStatus.completed:
        config = BannerConfig(
          icon: Icons.home_rounded,
          title: 'Rented',
          subtitle: 'Stay duration completed',
          colors: [AppColors.navyBlue, const Color(0xFF546E7A)],
          iconBg: const Color(0xFFEBEDF0),
        );
      case LeaseStatus.cancelled:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: config.colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: pulseAnim.value,
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: config.iconBg.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, size: 20, color: config.colors[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (config.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          config.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    final rid = lease.requestId;
    if (rid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: di.sl<RentRequestBloc>(),
          child: RentRequestDetailPage(
            requestId: rid,
            isSent: true,
          ),
        ),
      ),
    );
  }
}

class BannerConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color iconBg;

  const BannerConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.iconBg,
  });
}
