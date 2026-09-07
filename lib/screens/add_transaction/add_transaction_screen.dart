import 'package:flutter/material.dart';
import '../../widgets/add_transaction_bottom_sheet.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instead of a full screen, show the bottom sheet modal immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionBottomSheet(),
      ).then((_) {
        // When modal is closed, go back to previous screen
        Navigator.of(context).pop();
      });
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
