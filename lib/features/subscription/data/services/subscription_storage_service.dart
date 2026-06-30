import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar/core/utils/parse_utils.dart';
import 'package:aqar/features/subscription/domain/entities/listing_subscription_record.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/injection_container.dart' as di;

class SubscriptionStorageService {
  static const _storageKey = 'aqar_listing_subscriptions';

  Future<Map<int, ListingSubscriptionRecord>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) =>
          MapEntry(int.parse(k), ListingSubscriptionRecord.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<int, ListingSubscriptionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(records.map((k, v) => MapEntry(k.toString(), v.toJson())));
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> saveListingSubscription(ListingSubscriptionRecord record) async {
    final existing = await _readAll();
    final previous = existing[record.propertyId];
    existing[record.propertyId] = ListingSubscriptionRecord(
      propertyId: record.propertyId,
      subscriptionId: record.subscriptionId,
      propertyName: record.propertyName,
      planMonths: record.planMonths,
      amount: record.amount,
      paymentState: record.paymentState,
      createdAt: previous?.createdAt ?? record.createdAt,
      updatedAt: DateTime.now(),
    );
    await _writeAll(existing);
  }

  Future<ListingSubscriptionRecord?> getStoredListingSubscription(int propertyId) async {
    final records = await _readAll();
    return records[propertyId];
  }

  Future<void> updateStoredListingSubscriptionState(
    int propertyId,
    ListingSubscriptionPaymentState paymentState,
  ) async {
    final records = await _readAll();
    final current = records[propertyId];
    if (current == null) return;
    records[propertyId] = current.copyWith(
      paymentState: paymentState,
      updatedAt: DateTime.now(),
    );
    await _writeAll(records);
  }

  Future<ListingSubscriptionRecord?> syncStoredListingSubscriptionWithProperty(
    PropertyEntity property,
  ) async {
    if (property.listingType.value != 'for_sale') return null;

    final current = await getStoredListingSubscription(property.propertyId);
    if (current == null) return null;

    final hasActiveListing = property.listingStatus?.value == 'active' ||
        property.listingStatus?.value == 'under_negotiation' ||
        property.listingStatus?.value == 'sold' ||
        property.listingStatus?.value == 'expired';

    if (hasActiveListing && current.paymentState != ListingSubscriptionPaymentState.paid) {
      await updateStoredListingSubscriptionState(property.propertyId, ListingSubscriptionPaymentState.paid);
      return getStoredListingSubscription(property.propertyId);
    }

    return current;
  }

  Future<void> deleteStoredListingSubscription(int propertyId) async {
    final records = await _readAll();
    records.remove(propertyId);
    await _writeAll(records);
  }

  Future<ListingSubscriptionRecord?> createSubscriptionForProperty(
    int propertyId,
    int planMonths,
  ) async {
    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.post('/subscription/$propertyId', data: {
        'planMonths': planMonths,
      });
      final data = res.data;
      final record = ListingSubscriptionRecord(
        propertyId: propertyId,
        subscriptionId: data['subscription_id']?.toString() ?? '',
        propertyName: '',
        planMonths: planMonths,
        amount: parseDouble(data['amount']),
        paymentState: ListingSubscriptionPaymentState.unpaid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveListingSubscription(record);
      return record;
    } catch (_) {
      return null;
    }
  }

  Future<ListingSubscriptionRecord?> fetchSubscriptionFromApi(int propertyId) async {
    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.get('/subscription/$propertyId');
      final data = res.data;
      final months = parseInt(data['plan_months']);
      if (months < 1) return null;

      final status = data['status'] as String? ?? 'UNPAID';
      final record = ListingSubscriptionRecord(
        propertyId: propertyId,
        subscriptionId: data['subscription_id']?.toString() ?? '',
        propertyName: '',
        planMonths: months,
        amount: parseDouble(data['amount']),
        paymentState: ListingSubscriptionPaymentState.fromValue(status),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveListingSubscription(record);
      return record;
    } catch (_) {
      return null;
    }
  }
}
