import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rishtpak/constants/constants.dart';
import 'package:rishtpak/models/user_model.dart';

/// Golds top-up pack (consumable).
class GoldsPack {
  final String id;
  final String title;
  final int golds;
  final int amountInPaise;

  const GoldsPack({
    required this.id,
    required this.title,
    required this.golds,
    required this.amountInPaise,
  });
}

/// VIP subscription plan (duration based, stored on user_vip_until).
class VipPlan {
  final String id;
  final String title;
  final int days;
  final int amountInPaise;

  const VipPlan({
    required this.id,
    required this.title,
    required this.days,
    required this.amountInPaise,
  });
}

/// PaymentsService
///
/// Razorpay Checkout service for the Mallu cupid app:
///  - Golds wallet top-up packs
///  - VIP plans (extend the `user_vip_until` field)
///
/// On payment success it opens a Firestore [Transaction] that:
///  1. updates the user golds balance (USER_WALLET) or VIP expiry
///     (USER_VIP_UNTIL),
///  2. writes an audit record into the [C_PAYMENTS] ("Payments") collection.
class PaymentsService {
  // ---------------------------------------------------------------------
  // Catalog - adjust amounts (in paise, INR) from the Razorpay dashboard.
  // ---------------------------------------------------------------------
  static const List<GoldsPack> goldsPacks = <GoldsPack>[
    GoldsPack(
        id: 'golds_800',
        title: '800 Golds',
        golds: 800,
        amountInPaise: 9900), // ₹99
    GoldsPack(
        id: 'golds_1600',
        title: '1600 Golds',
        golds: 1600,
        amountInPaise: 18900), // ₹189
    GoldsPack(
        id: 'golds_3200',
        title: '3200 Golds',
        golds: 3200,
        amountInPaise: 34900), // ₹349
    GoldsPack(
        id: 'golds_6400',
        title: '6400 Golds',
        golds: 6400,
        amountInPaise: 64900), // ₹649
  ];

  static const List<VipPlan> vipPlans = <VipPlan>[
    VipPlan(
        id: 'vip_monthly',
        title: 'VIP - 1 Month',
        days: 30,
        amountInPaise: 29900), // ₹299
    VipPlan(
        id: 'vip_quarterly',
        title: 'VIP - 3 Months',
        days: 90,
        amountInPaise: 69900), // ₹699
    VipPlan(
        id: 'vip_yearly',
        title: 'VIP - 12 Months',
        days: 365,
        amountInPaise: 199900), // ₹1999
  ];

  // ---------------------------------------------------------------------
  // Service
  // ---------------------------------------------------------------------
  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// UI feedback callbacks (set by widgets like WalletProducts / VipPlans).
  Function(String message)? onPaymentSuccess;
  Function(String message)? onPaymentError;

  bool _listenersBound = false;

  void _ensureListeners() {
    if (_listenersBound) return;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _listenersBound = true;
  }

  /// Open Razorpay Checkout for a Golds top-up pack.
  Future<void> openGoldsCheckout(GoldsPack pack) async {
    await _openCheckout(
      amountInPaise: pack.amountInPaise,
      description: pack.title,
      productId: pack.id,
      type: 'golds',
    );
  }

  /// Open Razorpay Checkout for a VIP plan.
  Future<void> openVipCheckout(VipPlan plan) async {
    await _openCheckout(
      amountInPaise: plan.amountInPaise,
      description: plan.title,
      productId: plan.id,
      type: 'vip',
    );
  }

  Future<void> _openCheckout({
    required int amountInPaise,
    required String description,
    required String productId,
    required String type,
  }) async {
    // Guard: checkout cannot work without a valid key id.
    if (RAZORPAY_KEY_ID.isEmpty || RAZORPAY_KEY_ID.contains('XXXX')) {
      debugPaymentLog('Razorpay key is not configured. '
          'Set RAZORPAY_KEY_ID in lib/constants/constants.dart.');
      onPaymentError?.call(
          'Payments are not configured yet. Please try again later.');
      return;
    }

    _ensureListeners();

    final Map<String, Object> options = <String, Object>{
      'key': RAZORPAY_KEY_ID,
      'amount': amountInPaise,
      'currency': RAZORPAY_CURRENCY,
      'name': APP_NAME,
      'description': description,
      'prefill': <String, String>{
        'name': UserModel().user.userFullname,
        'contact': UserModel().user.userPhoneNumber,
        'email': UserModel().user.userEmail,
      },
      'notes': <String, String>{
        'user_id': UserModel().user.userId,
        'product_id': productId,
        'type': type,
      },
    };

    _openRazorpayCheckout(options);
  }

  void _openRazorpayCheckout(Map<String, Object> options) {
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPaymentLog('Razorpay open() -> error: $e');
      onPaymentError?.call('Unable to start the payment. Please try again.');
    }
  }

  // ---------------------------------------------------------------------
  // Razorpay event handlers
  // ---------------------------------------------------------------------
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPaymentLog('Razorpay payment success: ${response.paymentId}');

    try {
      final Map<String, String> notes =
          Map<String, String>.from(response.data?['notes'] ?? <String, String>{});
      final String type = notes['type'] ?? 'golds';
      final String productId = notes['product_id'] ?? '';

      int golds = 0;
      int vipDays = 0;
      int amountInPaise = 0;

      if (type == 'vip') {
        final VipPlan plan = vipPlans.firstWhere((p) => p.id == productId,
            orElse: () => vipPlans.first);
        vipDays = plan.days;
        amountInPaise = plan.amountInPaise;
      } else {
        final GoldsPack pack = goldsPacks.firstWhere((p) => p.id == productId,
            orElse: () => goldsPacks.first);
        golds = pack.golds;
        amountInPaise = pack.amountInPaise;
      }

      await _deliverProduct(
        type: type,
        productId: productId,
        golds: golds,
        vipDays: vipDays,
        amountInPaise: amountInPaise,
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      );

      onPaymentSuccess?.call(type == 'vip'
          ? 'VIP is now active on your account!'
          : 'Golds added to your wallet!');
    } catch (e) {
      debugPaymentLog('deliverProduct() -> error: $e');
      onPaymentError?.call('Payment received but delivery failed. '
          'Please contact support with payment id: ${response.paymentId}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPaymentLog(
        'Razorpay payment error: ${response.code} | ${response.message}');
    onPaymentError
        ?.call(response.message ?? 'Payment failed. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPaymentLog('Razorpay external wallet: ${response.walletName}');
  }

  // ---------------------------------------------------------------------
  // Firestore delivery (atomic transaction + audit record)
  // ---------------------------------------------------------------------
  Future<void> _deliverProduct({
    required String type,
    required String productId,
    required int golds,
    required int vipDays,
    required int amountInPaise,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final String userId = UserModel().user.userId;
    final DocumentReference userRef =
        _firestore.collection(C_USERS).doc(userId);
    final DocumentReference paymentRef = _firestore.collection(C_PAYMENTS).doc();

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot userDoc = await transaction.get(userRef);
      final Map<String, dynamic> userData =
          userDoc.data()! as Map<String, dynamic>;

      final Map<String, dynamic> updates = <String, dynamic>{};

      if (type == 'vip') {
        // Extend from the current expiry (or now if already expired).
        DateTime base = DateTime.now();
        final dynamic vipUntilRaw = userData[USER_VIP_UNTIL];
        if (vipUntilRaw is Timestamp && vipUntilRaw.toDate().isAfter(base)) {
          base = vipUntilRaw.toDate();
        }
        final DateTime vipUntil = base.add(Duration(days: vipDays));
        updates[USER_VIP_UNTIL] = Timestamp.fromDate(vipUntil);
      } else {
        updates[USER_WALLET] = FieldValue.increment(golds.toDouble());
      }

      transaction.update(userRef, updates);

      // Payments audit record.
      transaction.set(paymentRef, <String, dynamic>{
        'user_id': userId,
        'type': type, // golds | vip
        'product_id': productId,
        'golds': golds,
        'vip_days': vipDays,
        'amount': amountInPaise / 100.0,
        'currency': RAZORPAY_CURRENCY,
        'payment_id': paymentId,
        'order_id': orderId,
        'signature': signature,
        'status': 'success',
        'gateway': 'razorpay',
        TIMESTAMP: FieldValue.serverTimestamp(),
      });
    });

    // Refresh the local user object (wallet / vip status).
    final DocumentSnapshot refreshed = await UserModel().getUser(userId);
    UserModel().updateUserObject(refreshed.data()! as Map<String, dynamic>);
    if (type == 'vip') {
      await UserModel().refreshVipStatus();
    }
    debugPaymentLog('deliverProduct() -> success ($type)');
  }

  /// Release Razorpay listeners.
  void dispose() {
    if (_listenersBound) {
      _razorpay.clear();
      _listenersBound = false;
    }
  }

  void debugPaymentLog(String message) {
    print('PaymentsService -> $message');
  }
}
