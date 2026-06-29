import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/subscription/domain/entities/subscription_entity.dart';
import 'package:aqar/features/subscription/domain/entities/listing_subscription_record.dart';

enum SaleSubscriptionState {
  expired('Expired'),
  active('Active'),
  paidAwaitingVerification('Paid \u00b7 Pending Review'),
  awaitingVerification('Awaiting Review'),
  paymentPending('Payment Processing'),
  readyToPay('Verified \u00b7 Unpaid'),
  missingSubscription('Subscription Missing');

  final String label;
  const SaleSubscriptionState(this.label);
}

SaleSubscriptionState getSaleSubscriptionUiState(
  PropertyEntity property,
  ListingSubscriptionRecord? localSub,
  SubscriptionEntity? apiSub,
) {
  if (hasExpiredSaleListing(property)) return SaleSubscriptionState.expired;

  final hasActiveListing = property.listingStatus == ListingStatus.active ||
      property.listingStatus == ListingStatus.underNegotiation ||
      property.listingStatus == ListingStatus.sold;

  if (hasActiveListing) {
    return property.isVerified
        ? SaleSubscriptionState.active
        : SaleSubscriptionState.paidAwaitingVerification;
  }

  if (!property.isVerified) {
    if (localSub == null) {
      return SaleSubscriptionState.awaitingVerification;
    }
    if (localSub.paymentState == ListingSubscriptionPaymentState.paid) {
      return SaleSubscriptionState.paidAwaitingVerification;
    }
  }

  if (localSub?.paymentState == ListingSubscriptionPaymentState.pending) {
    return SaleSubscriptionState.paymentPending;
  }

  if (localSub?.paymentState == ListingSubscriptionPaymentState.unpaid) {
    return SaleSubscriptionState.readyToPay;
  }

  if (localSub?.paymentState == ListingSubscriptionPaymentState.paid) {
    return property.isVerified
        ? SaleSubscriptionState.active
        : SaleSubscriptionState.paidAwaitingVerification;
  }

  if (apiSub != null) {
    if (apiSub.status == 'PENDING') return SaleSubscriptionState.paymentPending;
    if (apiSub.status == 'UNPAID') return SaleSubscriptionState.readyToPay;
    if (apiSub.status == 'PAID' && property.isVerified) return SaleSubscriptionState.active;
    if (apiSub.status == 'PAID' && !property.isVerified) return SaleSubscriptionState.paidAwaitingVerification;
  }

  return SaleSubscriptionState.missingSubscription;
}

bool hasExpiredSaleListing(PropertyEntity property) {
  if (property.listingType != ListingType.forSale) return false;
  if (property.listingStatus == ListingStatus.expired) return true;
  if (property.listingExpiry != null && property.listingExpiry!.isBefore(DateTime.now())) return true;
  return false;
}
