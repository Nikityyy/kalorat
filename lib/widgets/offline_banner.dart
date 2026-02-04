import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final String language;

  const OfflineBanner({super.key, this.language = 'de'});

  @override
  Widget build(BuildContext context) {
    final message = language == 'de'
        ? 'Du bist offline. Die AI wird die Mahlzeit analysieren, sobald du wieder online bist.'
        : 'You are offline. The AI will analyze your meal once you are back online.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.wifi_slash : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
