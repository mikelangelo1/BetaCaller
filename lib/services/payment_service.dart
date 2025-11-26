import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:beta_caller/services/betacaller_api_service.dart';

enum PaymentGateway {
  paystack, // For Nigerian users (Naira)
  stripe,   // For international users (USD)
}

enum Currency {
  ngn, // Nigerian Naira
  usd, // US Dollar
}

class PaymentConfig {
  final PaymentGateway gateway;
  final Currency currency;
  final String currencySymbol;
  final String currencyCode;
  final double minimumAmount;
  final double maximumAmount;

  const PaymentConfig({
    required this.gateway,
    required this.currency,
    required this.currencySymbol,
    required this.currencyCode,
    required this.minimumAmount,
    required this.maximumAmount,
  });

  static const PaymentConfig naira = PaymentConfig(
    gateway: PaymentGateway.paystack,
    currency: Currency.ngn,
    currencySymbol: '₦',
    currencyCode: 'NGN',
    minimumAmount: 500.0,  // ₦500 minimum
    maximumAmount: 500000.0, // ₦500,000 maximum
  );

  static const PaymentConfig usd = PaymentConfig(
    gateway: PaymentGateway.stripe,
    currency: Currency.usd,
    currencySymbol: '\$',
    currencyCode: 'USD',
    minimumAmount: 1.0,  // $1 minimum
    maximumAmount: 1000.0, // $1000 maximum
  );
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? reference;
  final double amount;
  final Currency currency;
  final String? error;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.reference,
    required this.amount,
    required this.currency,
    this.error,
    this.metadata,
  });
}

class PaymentService extends ChangeNotifier {
  final BetaCallerApiService _apiService = BetaCallerApiService();

  // Current payment configuration (default: Naira)
  PaymentConfig _currentConfig = PaymentConfig.naira;

  // Exchange rate (NGN to USD)
  double _exchangeRate = 1650.0; // Example: ₦1650 = $1 (update from API)

  // Paystack keys
  String? _paystackPublicKey;

  PaymentConfig get currentConfig => _currentConfig;
  Currency get currentCurrency => _currentConfig.currency;
  String get currencySymbol => _currentConfig.currencySymbol;
  double get exchangeRate => _exchangeRate;

  /// Initialize payment service
  Future<void> initialize({
    required String paystackPublicKey,
    required String stripePublishableKey,
  }) async {
    // Store Paystack key
    _paystackPublicKey = paystackPublicKey;
    debugPrint('Paystack configured');

    // Initialize Stripe
    Stripe.publishableKey = stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.betacaller';
    await Stripe.instance.applySettings();
    debugPrint('Stripe initialized');
  }

  /// Switch payment gateway/currency
  void switchCurrency(Currency currency) {
    if (currency == Currency.ngn) {
      _currentConfig = PaymentConfig.naira;
    } else {
      _currentConfig = PaymentConfig.usd;
    }
    notifyListeners();
    debugPrint('Switched to ${_currentConfig.currencyCode}');
  }

  /// Get exchange rate from backend
  Future<void> updateExchangeRate() async {
    try {
      final response = await _apiService.getExchangeRate();
      if (response['success'] == true) {
        _exchangeRate = (response['rate'] as num).toDouble();
        notifyListeners();
        debugPrint('Exchange rate updated: ₦$_exchangeRate = \$1');
      }
    } catch (e) {
      debugPrint('Failed to update exchange rate: $e');
    }
  }

  /// Convert amount between currencies
  double convertAmount({
    required double amount,
    required Currency from,
    required Currency to,
  }) {
    if (from == to) return amount;

    if (from == Currency.usd && to == Currency.ngn) {
      return amount * _exchangeRate;
    } else if (from == Currency.ngn && to == Currency.usd) {
      return amount / _exchangeRate;
    }

    return amount;
  }

  /// Format amount with currency symbol
  String formatAmount(double amount, Currency currency) {
    final symbol = currency == Currency.ngn ? '₦' : '\$';
    if (currency == Currency.ngn) {
      return '$symbol${amount.toStringAsFixed(0)}'; // No decimals for Naira
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Validate amount
  bool validateAmount(double amount) {
    return amount >= _currentConfig.minimumAmount &&
           amount <= _currentConfig.maximumAmount;
  }

  /// Process payment based on selected gateway
  Future<PaymentResult> processPayment({
    required BuildContext context,
    required double amount,
    required String email,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    if (!validateAmount(amount)) {
      return PaymentResult(
        success: false,
        amount: amount,
        currency: _currentConfig.currency,
        error: 'Amount must be between ${formatAmount(_currentConfig.minimumAmount, _currentConfig.currency)} and ${formatAmount(_currentConfig.maximumAmount, _currentConfig.currency)}',
      );
    }

    try {
      if (_currentConfig.gateway == PaymentGateway.paystack) {
        return await _processPaystackPayment(
          context: context,
          amount: amount,
          email: email,
          phoneNumber: phoneNumber,
          metadata: metadata,
        );
      } else {
        return await _processStripePayment(
          context: context,
          amount: amount,
          email: email,
          metadata: metadata,
        );
      }
    } catch (e) {
      debugPrint('Payment processing error: $e');
      return PaymentResult(
        success: false,
        amount: amount,
        currency: _currentConfig.currency,
        error: 'Payment failed: $e',
      );
    }
  }

  /// Process Paystack payment (Naira) using backend initialization
  Future<PaymentResult> _processPaystackPayment({
    required BuildContext context,
    required double amount,
    required String email,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert amount to kobo (Paystack uses smallest currency unit)
      final amountInKobo = (amount * 100).toInt();

      // Generate reference
      final reference = 'BETA_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('Initiating Paystack payment: ₦$amount');

      // For Paystack, we'll use a webview-based approach
      // Since pay_with_paystack requires initialization in the widget,
      // we'll redirect to a payment page or use the backend to handle it

      // For now, we'll use the backend to initialize and return a payment URL
      // The mobile app can open this in a webview

      final response = await _apiService.initializePaystackPayment(
        amount: amountInKobo,
        email: email,
        reference: reference,
        metadata: metadata,
      );

      if (response['success'] == true) {
        final authorizationUrl = response['authorizationUrl'] as String?;
        final accessCode = response['accessCode'] as String?;

        if (authorizationUrl != null) {
          // Show payment webview
          final paymentCompleted = await _showPaystackWebview(
            context,
            authorizationUrl,
            reference,
          );

          if (paymentCompleted) {
            // Verify payment on backend
            final verificationResult = await _verifyPaystackPayment(reference);

            if (verificationResult['success'] == true) {
              return PaymentResult(
                success: true,
                transactionId: verificationResult['transactionId'],
                reference: reference,
                amount: amount,
                currency: Currency.ngn,
              );
            } else {
              return PaymentResult(
                success: false,
                reference: reference,
                amount: amount,
                currency: Currency.ngn,
                error: 'Payment verification failed: ${verificationResult['error']}',
              );
            }
          } else {
            return PaymentResult(
              success: false,
              amount: amount,
              currency: Currency.ngn,
              error: 'Payment was cancelled',
            );
          }
        }
      }

      return PaymentResult(
        success: false,
        amount: amount,
        currency: Currency.ngn,
        error: response['error'] ?? 'Failed to initialize payment',
      );
    } catch (e) {
      debugPrint('Paystack error: $e');
      return PaymentResult(
        success: false,
        amount: amount,
        currency: Currency.ngn,
        error: 'Paystack payment failed: $e',
      );
    }
  }

  /// Show Paystack payment webview
  Future<bool> _showPaystackWebview(
    BuildContext context,
    String authorizationUrl,
    String reference,
  ) async {
    // Navigate to webview payment screen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaystackWebviewScreen(
          authorizationUrl: authorizationUrl,
          reference: reference,
        ),
      ),
    );

    return result ?? false;
  }

  /// Process Stripe payment (USD)
  Future<PaymentResult> _processStripePayment({
    required BuildContext context,
    required double amount,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('Initiating Stripe payment: \$$amount');

      // Create payment intent on backend
      final paymentIntentResponse = await _apiService.createStripePaymentIntent(
        amount: amount,
        currency: 'usd',
        email: email,
        metadata: metadata,
      );

      if (paymentIntentResponse['success'] != true) {
        return PaymentResult(
          success: false,
          amount: amount,
          currency: Currency.usd,
          error: 'Failed to create payment intent: ${paymentIntentResponse['error']}',
        );
      }

      final clientSecret = paymentIntentResponse['clientSecret'] as String;
      final paymentIntentId = paymentIntentResponse['paymentIntentId'] as String;

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'BetaCaller',
          paymentIntentClientSecret: clientSecret,
          customerId: paymentIntentResponse['customerId'],
          customerEphemeralKeySecret: paymentIntentResponse['ephemeralKey'],
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Stripe payment successful: $paymentIntentId');

      // Verify payment on backend
      final verificationResult = await _verifyStripePayment(paymentIntentId);

      if (verificationResult['success'] == true) {
        return PaymentResult(
          success: true,
          transactionId: verificationResult['transactionId'],
          reference: paymentIntentId,
          amount: amount,
          currency: Currency.usd,
        );
      } else {
        return PaymentResult(
          success: false,
          reference: paymentIntentId,
          amount: amount,
          currency: Currency.usd,
          error: 'Payment verification failed: ${verificationResult['error']}',
        );
      }
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      return PaymentResult(
        success: false,
        amount: amount,
        currency: Currency.usd,
        error: e.error.localizedMessage ?? 'Payment cancelled or failed',
      );
    } catch (e) {
      debugPrint('Stripe payment error: $e');
      return PaymentResult(
        success: false,
        amount: amount,
        currency: Currency.usd,
        error: 'Stripe payment failed: $e',
      );
    }
  }

  /// Verify Paystack payment on backend
  Future<Map<String, dynamic>> _verifyPaystackPayment(String reference) async {
    try {
      return await _apiService.verifyPaystackPayment(reference);
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification failed: $e',
      };
    }
  }

  /// Verify Stripe payment on backend
  Future<Map<String, dynamic>> _verifyStripePayment(String paymentIntentId) async {
    try {
      return await _apiService.verifyStripePayment(paymentIntentId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification failed: $e',
      };
    }
  }

  /// Get suggested amounts based on currency
  List<double> getSuggestedAmounts() {
    if (_currentConfig.currency == Currency.ngn) {
      return [1000.0, 2000.0, 5000.0, 10000.0, 20000.0, 50000.0];
    } else {
      return [5.0, 10.0, 20.0, 50.0, 100.0, 200.0];
    }
  }

  /// Get minimum top-up amount
  double getMinimumAmount() => _currentConfig.minimumAmount;

  /// Get maximum top-up amount
  double getMaximumAmount() => _currentConfig.maximumAmount;
}

/// Paystack Webview Payment Screen
class PaystackWebviewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebviewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaystackWebviewScreen> createState() => _PaystackWebviewScreenState();
}

class _PaystackWebviewScreenState extends State<PaystackWebviewScreen> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // For now, we'll show a placeholder that instructs to use webview
    // In production, you'd use webview_flutter package
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Paystack Payment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Complete your payment securely with Paystack',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // In production, replace with actual webview
            ElevatedButton.icon(
              onPressed: () {
                // Simulate successful payment for testing
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Simulate Successful Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
