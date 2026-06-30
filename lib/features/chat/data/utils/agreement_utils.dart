import 'dart:convert';
import 'package:aqar/core/utils/parse_utils.dart';

enum AgreementMessageType { request, accepted, declined, none }

class AgreementData {
  final int propertyId;
  final String propertyName;
  final double price;
  final String terms;
  final AgreementMessageType type;

  const AgreementData({
    required this.propertyId,
    required this.propertyName,
    required this.price,
    this.terms = '',
    this.type = AgreementMessageType.request,
  });

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'propertyName': propertyName,
        'price': price,
        'terms': terms,
      };

  static AgreementData? fromJson(Map<String, dynamic> json) {
    try {
      return AgreementData(
        propertyId: json['propertyId'] as int,
        propertyName: json['propertyName'] as String? ?? '',
        price: parseDouble(json['price']),
        terms: json['terms'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

class AgreementUtils {
  static const _prefixRequest = '[AGREEMENT]';
  static const _prefixAccepted = '[AGREEMENT_ACCEPT]';
  static const _prefixDeclined = '[AGREEMENT_DECLINE]';

  static String encodeRequest(AgreementData data) {
    return '$_prefixRequest${jsonEncode(data.toJson())}';
  }

  static String encodeAccept(int propertyId) {
    return '$_prefixAccepted{"propertyId":$propertyId}';
  }

  static String encodeDecline(int propertyId) {
    return '$_prefixDeclined{"propertyId":$propertyId}';
  }

  static (AgreementMessageType, AgreementData?) parse(String content) {
    if (content.startsWith(_prefixRequest)) {
      final jsonStr = content.substring(_prefixRequest.length);
      try {
        final data = AgreementData.fromJson(jsonDecode(jsonStr));
        return (AgreementMessageType.request, data);
      } catch (_) {
        return (AgreementMessageType.none, null);
      }
    }
    if (content.startsWith(_prefixAccepted)) {
      return (AgreementMessageType.accepted, null);
    }
    if (content.startsWith(_prefixDeclined)) {
      return (AgreementMessageType.declined, null);
    }
    return (AgreementMessageType.none, null);
  }

  static bool isAgreementMessage(String content) {
    return content.startsWith(_prefixRequest) ||
        content.startsWith(_prefixAccepted) ||
        content.startsWith(_prefixDeclined);
  }
}
