import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';

class LocalSubscriptionService {
  static const _prefix = 'listing_subscription_';

  static Future<SubscriptionEntity?> getStoredSubscription(int propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$propertyId');
    if (json == null) return null;
    try {
      return SubscriptionEntity.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  static Future<void> storeSubscription(int propertyId, SubscriptionEntity subscription) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$propertyId', jsonEncode({
      'subscription_id': subscription.subscriptionId,
      'property_id': subscription.propertyId,
      'owner_id': subscription.ownerId,
      'plan_months': subscription.planMonths,
      'amount': subscription.amount,
      'status': subscription.status,
      'created_at': subscription.createdAt?.toIso8601String(),
    }));
  }

  static Future<void> updateSubscriptionState(int propertyId, String newStatus) async {
    final existing = await getStoredSubscription(propertyId);
    if (existing != null) {
      await storeSubscription(
        propertyId,
        SubscriptionEntity(
          subscriptionId: existing.subscriptionId,
          propertyId: existing.propertyId,
          ownerId: existing.ownerId,
          planMonths: existing.planMonths,
          amount: existing.amount,
          status: newStatus,
          createdAt: existing.createdAt,
        ),
      );
    }
  }

  static Future<void> removeSubscription(int propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$propertyId');
  }

  static Future<SubscriptionEntity?> syncWithProperty(PropertyEntity property) async {
    if (property.listingType != ListingType.forSale) return null;

    final stored = await getStoredSubscription(property.propertyId);
    if (stored == null) return null;

    final hasActiveListing = property.listingStatus == ListingStatus.active ||
        property.listingStatus == ListingStatus.underNegotiation ||
        property.listingStatus == ListingStatus.sold ||
        property.listingStatus == ListingStatus.expired;

    if (hasActiveListing && stored.status != 'PAID') {
      await updateSubscriptionState(property.propertyId, 'PAID');
      return getStoredSubscription(property.propertyId);
    }

    return stored;
  }
}
