import 'package:flutter/material.dart';
import '../../domain/models/checkout_step_model.dart';
import '../../domain/models/checkout_session_model.dart';

class CheckoutProgressIndicator extends StatelessWidget {
  final List<CheckoutStepModel> steps;
  final CheckoutStepType currentStep;
  final Function(CheckoutStepType)? onStepTapped;
  final bool allowNavigation;

  const CheckoutProgressIndicator({
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
    this.allowNavigation = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProgressSteps(),
        if (allowNavigation) _buildNavigationHint(),
      ],
    );
  }

  Widget _buildProgressSteps() {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              steps.length - 1,
              (index) => Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(
                    right: index < steps.length - 2 ? 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: _getStepProgressColor(steps[index]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Step indicators
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = step.isCompleted;
            final isCurrent = step.type == currentStep;
            final isClickable = allowNavigation && (isCompleted || _isStepAccessible(step));

            return Expanded(
              child: GestureDetector(
                onTap: isClickable ? () => onStepTapped?.call(step.type) : null,
                child: Column(
                  children: [
                    _buildStepIndicator(step, isCompleted, isCurrent, isClickable),
                    const SizedBox(height: 8),
                    _buildStepLabel(step, isCompleted, isCurrent),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    CheckoutStepModel step,
    bool isCompleted,
    bool isCurrent,
    bool isClickable,
  ) {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;

    if (isCompleted) {
      backgroundColor = Colors.green;
      borderColor = Colors.green;
      iconColor = Colors.white;
    } else if (isCurrent) {
      backgroundColor = Theme.of(context).primaryColor;
      borderColor = Theme.of(context).primaryColor;
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade300;
      iconColor = Colors.grey.shade500;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: iconColor,
                size: 20,
              )
            : Text(
                '${step.order}',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLabel(
    CheckoutStepModel step,
    bool isCompleted,
    bool isCurrent,
  ) {
    Color textColor;
    FontWeight fontWeight;

    if (isCompleted) {
      textColor = Colors.green.shade700;
      fontWeight = FontWeight.w600;
    } else if (isCurrent) {
      textColor = Theme.of(context).primaryColor;
      fontWeight = FontWeight.bold;
    } else {
      textColor = Colors.grey.shade600;
      fontWeight = FontWeight.normal;
    }

    return Column(
      children: [
        Text(
          step.title,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          step.subtitle,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontWeight: FontWeight.normal,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNavigationHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Tap on completed steps to navigate back',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getStepProgressColor(CheckoutStepModel step) {
    if (step.isCompleted) {
      return Colors.green;
    } else if (step.type == currentStep) {
      return Theme.of(context).primaryColor;
    } else {
      return Colors.grey.shade300;
    }
  }

  bool _isStepAccessible(CheckoutStepModel step) {
    // Allow navigation to any step before the current step
    final steps = CheckoutStepDefinition.getStandardSteps();
    final currentIndex = steps.indexWhere((s) => s.type == currentStep);
    final stepIndex = steps.indexWhere((s) => s.type == step.type);

    return stepIndex < currentIndex;
  }
}

class CheckoutProgressIndicatorWithSecurity extends StatelessWidget {
  final List<CheckoutStepModel> steps;
  final CheckoutStepType currentStep;
  final CheckoutSessionModel session;
  final Function(CheckoutStepType)? onStepTapped;
  final bool allowNavigation;
  final bool showSecurityBadge;

  const CheckoutProgressIndicatorWithSecurity({
    required this.steps,
    required this.currentStep,
    required this.session,
    this.onStepTapped,
    this.allowNavigation = false,
    this.showSecurityBadge = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSecurityBadge) _buildSecurityBadge(),
        CheckoutProgressIndicator(
          steps: steps,
          currentStep: currentStep,
          onStepTapped: onStepTapped,
          allowNavigation: allowNavigation,
        ),
        _buildSessionInfo(),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    final securityLevel = session.securityContext['securityLevel'] as String? ?? 'standard';
    final Color badgeColor = _getSecurityBadgeColor(securityLevel);
    final IconData badgeIcon = _getSecurityBadgeIcon(securityLevel);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: badgeColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Security: ${securityLevel.toUpperCase()}',
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    final expiresAt = session.expiresAt;
    final now = DateTime.now();
    final remaining = expiresAt.difference(now);

    String timeRemaining;
    if (remaining.inMinutes > 0) {
      timeRemaining = '${remaining.inMinutes} minutes';
    } else {
      timeRemaining = '${remaining.inSeconds} seconds';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.orange.shade700,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Session expires in $timeRemaining',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSecurityBadgeColor(String securityLevel) {
    switch (securityLevel.toLowerCase()) {
      case 'maximum':
        return Colors.green;
      case 'high':
        return Colors.blue;
      case 'standard':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSecurityBadgeIcon(String securityLevel) {
    switch (securityLevel.toLowerCase()) {
      case 'maximum':
        return Icons.security;
      case 'high':
        return Icons.shield;
      case 'standard':
        return Icons.lock_outline;
      case 'low':
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }
}