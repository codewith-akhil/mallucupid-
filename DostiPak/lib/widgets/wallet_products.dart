import 'package:flutter/material.dart';
import 'package:rishtpak/services/payments_service.dart';

/// WalletProducts
///
/// Grid of Golds top-up packs. Tapping a pack opens the Razorpay Checkout
/// via [PaymentsService] and, on success, tops-up the user's golds wallet.
class WalletProducts extends StatefulWidget {
  const WalletProducts({super.key});

  @override
  State<WalletProducts> createState() => _WalletProductsState();
}

class _WalletProductsState extends State<WalletProducts> {
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: PaymentsService.goldsPacks.length,
      itemBuilder: (context, index) {
        final GoldsPack pack = PaymentsService.goldsPacks[index];
        return _buildGoldsPackCard(context, pack);
      },
    );
  }

  Widget _buildGoldsPackCard(BuildContext context, GoldsPack pack) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _paymentsService.openGoldsCheckout(pack),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/icon_money.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.monetization_on, color: Colors.amber),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${pack.golds} Golds',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatPrice(pack.amountInPaise),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
