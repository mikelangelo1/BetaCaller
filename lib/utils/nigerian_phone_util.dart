class NigerianPhoneUtil {
  // Nigerian carrier prefixes
  static const Map<String, List<String>> carrierPrefixes = {
    'MTN': ['803', '806', '810', '813', '814', '816', '903', '906'],
    'Glo': ['805', '807', '811', '815', '905'],
    'Airtel': ['802', '808', '812', '901', '902', '904', '907'],
    '9mobile': ['809', '817', '818', '909'],
  };

  /// Format Nigerian number to E.164 format
  /// Examples:
  /// - 08012345678 → +2348012345678
  /// - 2348012345678 → +2348012345678
  /// - +2348012345678 → +2348012345678
  static String formatToE164(String number) {
    // Remove all non-digit characters except +
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    // Already in E.164 format
    if (cleaned.startsWith('+234') && cleaned.length == 14) {
      return cleaned;
    }

    // Remove leading + if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Nigerian number starting with 234
    if (cleaned.startsWith('234')) {
      if (cleaned.length == 13) {
        return '+$cleaned';
      }
    }

    // Nigerian number starting with 0
    if (cleaned.startsWith('0')) {
      if (cleaned.length == 11) {
        return '+234${cleaned.substring(1)}';
      }
    }

    // Default: assume it's a Nigerian number without country code or leading zero
    if (cleaned.length == 10) {
      return '+234$cleaned';
    }

    // Return original if we can't format it
    return number;
  }

  /// Format for display (Nigerian format)
  /// +2348012345678 → 0801 234 5678
  static String formatForDisplay(String number) {
    final e164 = formatToE164(number);

    if (e164.startsWith('+234') && e164.length == 14) {
      final nationalNumber = e164.substring(4); // Remove +234
      if (nationalNumber.length == 10) {
        return '0${nationalNumber.substring(0, 3)} ${nationalNumber.substring(3, 6)} ${nationalNumber.substring(6)}';
      }
    }

    return number;
  }

  /// Detect carrier from Nigerian phone number
  static String? detectCarrier(String number) {
    final e164 = formatToE164(number);

    // Only work with Nigerian numbers
    if (!e164.startsWith('+234')) {
      return null;
    }

    // Get the prefix (first 3 digits after country code and leading digit)
    final nationalNumber = e164.substring(4); // Remove +234
    if (nationalNumber.length < 3) {
      return null;
    }

    final prefix = nationalNumber.substring(0, 3);

    // Check each carrier's prefixes
    for (final entry in carrierPrefixes.entries) {
      if (entry.value.contains(prefix)) {
        return entry.key;
      }
    }

    return null;
  }

  /// Check if number is a valid Nigerian mobile number
  static bool isValidNigerianMobile(String number) {
    final e164 = formatToE164(number);

    // Must be Nigerian number
    if (!e164.startsWith('+234')) {
      return false;
    }

    // Must be correct length (14 characters including +234)
    if (e164.length != 14) {
      return false;
    }

    // Must belong to a known carrier
    return detectCarrier(e164) != null;
  }

  /// Check if number is a Nigerian landline
  /// Landlines in Nigeria typically start with 01, 02, 04, etc.
  static bool isNigerianLandline(String number) {
    final e164 = formatToE164(number);

    if (!e164.startsWith('+234')) {
      return false;
    }

    final nationalNumber = e164.substring(4);
    if (nationalNumber.isEmpty) {
      return false;
    }

    // Landlines start with 01, 02, 04, 05, 07, 08, 09 (but not mobile prefixes)
    final firstDigit = nationalNumber[0];
    if (firstDigit == '0') {
      return false; // Mobile numbers have 0 as first digit in national format
    }

    // Check if it's a known mobile prefix
    if (nationalNumber.length >= 3) {
      final prefix = nationalNumber.substring(0, 3);
      for (final prefixList in carrierPrefixes.values) {
        if (prefixList.contains(prefix)) {
          return false; // It's a mobile number
        }
      }
    }

    return true;
  }

  /// Get network type (mobile or landline)
  static String getNetworkType(String number) {
    if (isValidNigerianMobile(number)) {
      return 'mobile';
    } else if (isNigerianLandline(number)) {
      return 'landline';
    }
    return 'unknown';
  }

  /// Get carrier icon/color for UI
  static Map<String, dynamic> getCarrierInfo(String? carrier) {
    switch (carrier) {
      case 'MTN':
        return {
          'name': 'MTN',
          'color': 0xFFFFCB05, // MTN Yellow
          'icon': '📱',
        };
      case 'Glo':
        return {
          'name': 'Glo',
          'color': 0xFF00A859, // Glo Green
          'icon': '📱',
        };
      case 'Airtel':
        return {
          'name': 'Airtel',
          'color': 0xFFED1C24, // Airtel Red
          'icon': '📱',
        };
      case '9mobile':
        return {
          'name': '9mobile',
          'color': 0xFF006F3F, // 9mobile Green
          'icon': '📱',
        };
      default:
        return {
          'name': 'Unknown',
          'color': 0xFF757575,
          'icon': '📞',
        };
    }
  }

  /// Parse international number (basic support for other countries)
  static Map<String, String> parseInternationalNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Nigeria
    if (cleaned.startsWith('234')) {
      return {
        'countryCode': 'NG',
        'dialCode': '234',
        'nationalNumber': cleaned.substring(3),
        'e164': '+$cleaned',
      };
    }

    // US/Canada
    if (cleaned.startsWith('1') && cleaned.length == 11) {
      return {
        'countryCode': 'US',
        'dialCode': '1',
        'nationalNumber': cleaned.substring(1),
        'e164': '+$cleaned',
      };
    }

    // UK
    if (cleaned.startsWith('44')) {
      return {
        'countryCode': 'GB',
        'dialCode': '44',
        'nationalNumber': cleaned.substring(2),
        'e164': '+$cleaned',
      };
    }

    // Ghana
    if (cleaned.startsWith('233')) {
      return {
        'countryCode': 'GH',
        'dialCode': '233',
        'nationalNumber': cleaned.substring(3),
        'e164': '+$cleaned',
      };
    }

    // Kenya
    if (cleaned.startsWith('254')) {
      return {
        'countryCode': 'KE',
        'dialCode': '254',
        'nationalNumber': cleaned.substring(3),
        'e164': '+$cleaned',
      };
    }

    // South Africa
    if (cleaned.startsWith('27')) {
      return {
        'countryCode': 'ZA',
        'dialCode': '27',
        'nationalNumber': cleaned.substring(2),
        'e164': '+$cleaned',
      };
    }

    // Default/Unknown
    return {
      'countryCode': 'UNKNOWN',
      'dialCode': cleaned.length >= 3 ? cleaned.substring(0, 3) : cleaned,
      'nationalNumber': cleaned.length >= 3 ? cleaned.substring(3) : '',
      'e164': '+$cleaned',
    };
  }

  /// Validate any phone number format
  static bool isValidPhoneNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

    // Must have at least 10 digits
    if (cleaned.replaceAll('+', '').length < 10) {
      return false;
    }

    // Must not have multiple + signs
    if (cleaned.split('+').length > 2) {
      return false;
    }

    // + must be at the start if present
    if (cleaned.contains('+') && !cleaned.startsWith('+')) {
      return false;
    }

    return true;
  }

  /// Get formatted number with carrier badge
  static String getFormattedWithCarrier(String number) {
    final carrier = detectCarrier(number);
    final formatted = formatForDisplay(number);

    if (carrier != null) {
      return '$formatted ($carrier)';
    }

    return formatted;
  }
}
