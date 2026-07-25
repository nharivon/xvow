import 'package:flutter/material.dart';

import '../../../shared/widgets/xvow_widgets.dart';

class PaymentInfoScreen extends StatelessWidget {
  const PaymentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements · Information')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          AppCard(
            child: Text(
              'Les dépôts de 2 \$ et les pénalités de 1 \$ sont fictifs. Ils servent uniquement à renforcer l’engagement psychologique.',
            ),
          ),
          SizedBox(height: 12),
          AppCard(
            child: Text(
              'Aucun paiement réel n’est effectué dans cette version MVP.',
            ),
          ),
        ],
      ),
    );
  }
}
