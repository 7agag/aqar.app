import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_event.dart';
import 'package:aqar/features/sponsor/presentation/pages/sponsorship_page.dart';
import 'package:aqar/core/localization/app_strings.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/injection_container.dart' as di;

void showPropertyActionSheet(BuildContext context, PropertyEntity property) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              AppStrings.editProperty,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            _actionTile(
              icon: Icons.rocket_launch_rounded,
              title: AppStrings.promote,
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SponsorshipPage(
                      propertyId: property.propertyId,
                    ),
                  ),
                );
              },
            ),
            _actionTile(
              icon: Icons.visibility_off_rounded,
              title: AppStrings.unlist,
              color: AppColors.navyBlue,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppStrings.unlist),
                    content: Text(AppStrings.unlistConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppStrings.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(AppStrings.confirm),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await di.sl<ApiClient>().dio.put(
                      '/property/${property.propertyId}',
                      data: {'listing_status': 'inactive'},
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${AppStrings.success}!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context
                          .read<PropertyBloc>()
                          .add(GetPropertyByIdRequested(id: property.propertyId));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.somethingWentWrong),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            _actionTile(
              icon: Icons.delete_outline_rounded,
              title: AppStrings.delete,
              color: AppColors.error,
              isDestructive: true,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppStrings.delete),
                    content: Text(AppStrings.deleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppStrings.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          AppStrings.delete,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await di.sl<ApiClient>().dio.delete(
                      '/property/${property.propertyId}',
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.somethingWentWrong),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _actionTile({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: (isDestructive ? AppColors.error : color).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
