import 'package:flutter/material.dart';
import 'package:rishtpak/services/payments_service.dart';

/// VipPlans
///
/// List of VIP plans. Tapping a plan opens the Razorpay Checkout via
/// [PaymentsService] and, on success, extends the user's `user_vip_until`.
class VipPlans extends StatefulWidget {
  const VipPlans({super.key});

  @override
  State<VipPlans> createState() => _VipPlansState();
}

class _VipPlansState extends State<VipPlans> {
  final PaymentsService _paymentsService = PaymentsService();

  @override
  void initState() {
    super.initState();
    _paymentsService.onPaymentSuccess = (String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    };
    _paymentsService.onPaymentError = (String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    };
  }

  @override
  void dispose() {
    _paymentsService.onPaymentSuccess = null;
    _paymentsService.onPaymentError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentsService.vipPlans
          .map((plan) => _buildVipPlanCard(context, plan))
          .toList(),
    );
  }

  Widget _buildVipPlanCard(BuildContext context, VipPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Image.asset(
          'assets/badges/crown_badge.png',
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.workspace_premium,
            color: Colors.amber,
            size: 36,
          ),
        ),
        title: Text(
          plan.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _formatPrice(plan.amountInPaise),
          style: TextStyle(
            fontSize: 17,
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'BUY',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => _paymentsService.openVipCheckout(plan),
        ),
      ),
    );
  }

  String _formatPrice(int amountInPaise) {
    final double rupees = amountInPaise / 100.0;
    return rupees == rupees.roundToDouble()
        ? '₹${rupees.toStringAsFixed(0)}'
        : '₹${rupees.toStringAsFixed(2)}';
  }
}
