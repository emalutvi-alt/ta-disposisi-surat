import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/network/api_exception.dart';

void showApiError(BuildContext context, Object error) {
  final msg = error is ApiException
      ? error.message
      : 'Terjadi kesalahan. Coba lagi.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

Widget buildLoading() => const Center(child: CircularProgressIndicator());

Widget buildEmpty(String text) => Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );

Widget buildError(String message, VoidCallback onRetry) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
