import 'package:flutter/material.dart';

Future<String?> showBarcodeScannerDialog(BuildContext context, {bool isOnlineOrder = false}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Masukkan Barcode'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Scan atau ketik barcode...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.qr_code_scanner),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.pop(ctx, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(ctx, value);
            }
          },
          child: const Text('Cari'),
        ),
      ],
    ),
  );
}
