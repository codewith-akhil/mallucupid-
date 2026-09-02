import 'package:flutter/material.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/widgets/vip_plans.dart';
import 'package:rishtpak/widgets/wallet_products.dart';

/// VipDialog
///
/// Modern English VIP / recharge dialog:
///  - VIP plans (Razorpay Checkout via VipPlans widget)
///  - Golds wallet top-up packs (Razorpay Checkout via WalletProducts widget)
class VipDialog extends StatelessWidget {
  const VipDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Dialog(
      // Bottom inset keeps the tall scrollable dialog clear of the Android
      // nav bar (3-button / gesture) on edge-to-edge.
      insetPadding: EdgeInsets.fromLTRB(12, 30, 12,
          MediaQuery.of(context).padding.bottom + 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: <Widget>[
              /// Header
              Container(
                color: Theme.of(context).primaryColor,
                width: double.maxFinite,
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            /// User image
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                                child:
                                    Image.asset('assets/images/crow_badge.png'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(i18n.translate("vip_account"),
                                  style: const TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),

                            // User account
                            ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                                backgroundImage: NetworkImage(
                                    UserModel().user.userProfilePhoto),
                              ),
                              title: Text(
                                  '${i18n.translate("hello")} ${UserModel().user.userFullname.split(' ')[0]}, '
                                  '${i18n.translate("please_recharge_your_credit")}',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white),
                                  textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 8)
                          ],
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: Colors.white, size: 35),
                              onPressed: () {
                                /// Close Dialog
                                Navigator.of(context).pop();
                              }),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              /// VIP Plans (Razorpay Checkout)
              Container(
                width: double.maxFinite,
                color: Colors.grey.withAlpha(70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(i18n.translate("vip_subscriptions"),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 10, thickness: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: VipPlans(),
                    ),
                    const Divider(thickness: 1),
                  ],
                ),
              ),
              const Divider(),

              /// Golds recharge (Razorpay Checkout)
              Container(
                width: double.maxFinite,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(i18n.translate("recharge"),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 10, thickness: 1),

                    /// Golds top-up packs
                    const WalletProducts(),

                    const SizedBox(height: 10),

                    /// VIP benefits
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'VIP members enjoy unlimited chatting, '
                        'voice messages, media sharing and more.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
