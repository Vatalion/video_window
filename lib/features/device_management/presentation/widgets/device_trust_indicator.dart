import 'package:flutter/material.dart';

class DeviceTrustIndicator extends StatelessWidget {
  final int trustScore;

  const DeviceTrustIndicator({super.key, required this.trustScore});

  @override
  Widget build(BuildContext context) {
    final trustLevel = _getTrustLevel(trustScore);
    final color = _getTrustColor(trustLevel);
    final text = _getTrustText(trustLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrustIcon(trustLevel),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$trustScore% $text',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  TrustLevel _getTrustLevel(int score) {
    if (score >= 80) return TrustLevel.high;
    if (score >= 50) return TrustLevel.medium;
    return TrustLevel.low;
  }

  Color _getTrustColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return Colors.green;
      case TrustLevel.medium:
        return Colors.orange;
      case TrustLevel.low:
        return Colors.red;
    }
  }

  String _getTrustText(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return 'Trusted';
      case TrustLevel.medium:
        return 'Medium';
      case TrustLevel.low:
        return 'Low';
    }
  }

  IconData _getTrustIcon(TrustLevel level) {
    switch (level) {
      case TrustLevel.high:
        return Icons.verified;
      case TrustLevel.medium:
        return Icons.warning_amber;
      case TrustLevel.low:
        return Icons.error_outline;
    }
  }
}

enum TrustLevel { high, medium, low }