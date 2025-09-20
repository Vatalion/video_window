import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';
import '../widgets/checkout_progress_indicator_with_security.dart';
import '../widgets/checkout_security_banner.dart';
import '../widgets/order_summary_widget.dart';
import '../widgets/guest_checkout_widget.dart';
import '../../domain/models/checkout_step_model.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../domain/models/order_summary_model.dart';

class CheckoutPage extends StatefulWidget {
  final String? userId;
  final bool isGuest;
  final String? sessionId;

  const CheckoutPage({
    this.userId,
    this.isGuest = false,
    this.sessionId,
    super.key,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late CheckoutBloc _checkoutBloc;
  CheckoutSessionModel? _currentSession;
  SecurityContextModel? _currentSecurityContext;
  OrderSummaryModel? _currentOrderSummary;

  @override
  void initState() {
    super.initState();
    _checkoutBloc = CheckoutBloc(
      repository: // This would be injected via dependency injection
        throw UnimplementedError('Repository must be provided'),
      validateCheckoutStepUseCase: throw UnimplementedError(),
      saveCheckoutSessionUseCase: throw UnimplementedError(),
      resumeCheckoutSessionUseCase: throw UnimplementedError(),
      completeCheckoutUseCase: throw UnimplementedError(),
    );

    _initializeCheckout();
  }

  void _initializeCheckout() {
    if (widget.sessionId != null) {
      // Resume existing session
      _checkoutBloc.add(
        CheckoutSessionResumed(
          sessionId: widget.sessionId!,
          userId: widget.userId ?? 'guest',
        ),
      );
    } else if (widget.userId != null) {
      // Start new session
      _checkoutBloc.add(
        CheckoutStarted(
          userId: widget.userId!,
          isGuest: widget.isGuest,
        ),
      );
    }
  }

  @override
  void dispose() {
    _checkoutBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _checkoutBloc,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, state) {
            _handleStateChange(state);
          },
          child: BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, state) {
              return _buildBody(context, state);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Checkout'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      actions: [
        IconButton(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Checkout Help',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState state) {
    if (state is CheckoutLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is CheckoutError) {
      return _buildErrorView(context, state);
    }

    if (state is CheckoutTimeout) {
      return _buildTimeoutView(context, state);
    }

    if (state is CheckoutAuthenticationRequired) {
      return _buildAuthenticationRequiredView(context, state);
    }

    if (state is CheckoutCompleted) {
      return _buildCompletionView(context, state);
    }

    return _buildCheckoutContent(context, state);
  }

  Widget _buildCheckoutContent(BuildContext context, CheckoutState state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressSection(context, state),
                const SizedBox(height: 24),
                _buildSecuritySection(context, state),
                const SizedBox(height: 24),
                _buildCurrentStepContent(context, state),
                const SizedBox(height: 24),
                _buildOrderSummarySection(context, state),
              ],
            ),
          ),
        ),
        _buildBottomActionButtons(context, state),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, CheckoutState state) {
    CheckoutSessionModel? session;
    CheckoutStepType currentStep = CheckoutStepType.cartReview;

    if (state is CheckoutSessionCreated) {
      session = state.session;
      _currentSession = session;
      currentStep = session.currentStep;
    } else if (state is CheckoutSessionLoaded) {
      session = state.session;
      _currentSession = session;
      currentStep = session.currentStep;
    } else if (state is CheckoutSessionResumed) {
      session = state.session;
      _currentSession = session;
      currentStep = session.currentStep;
    } else if (state is CheckoutStepInProgress) {
      session = state.session;
      currentStep = state.currentStep;
    }

    if (session == null) {
      return const SizedBox.shrink();
    }

    return CheckoutProgressIndicatorWithSecurity(
      steps: CheckoutStepDefinition.getStandardSteps(),
      currentStep: currentStep,
      session: session,
      onStepTapped: (stepType) {
        if (session.completedSteps.contains(stepType)) {
          _checkoutBloc.add(
            CheckoutStepChanged(
              stepType: stepType,
              sessionId: session.sessionId,
            ),
          );
        }
      },
      allowNavigation: true,
    );
  }

  Widget _buildSecuritySection(BuildContext context, CheckoutState state) {
    SecurityContextModel? securityContext;

    if (state is CheckoutSessionCreated) {
      securityContext = state.securityContext;
      _currentSecurityContext = securityContext;
    } else if (state is CheckoutSessionLoaded) {
      securityContext = state.securityContext;
      _currentSecurityContext = securityContext;
    } else if (state is CheckoutSessionResumed) {
      securityContext = state.securityContext;
      _currentSecurityContext = securityContext;
    } else if (state is CheckoutStepInProgress) {
      securityContext = state.securityContext;
    }

    if (securityContext == null) {
      return const SizedBox.shrink();
    }

    return CheckoutSecurityBanner(
      securityContext: securityContext,
      onRefreshSecurity: () {
        _checkoutBloc.add(
          CheckoutSecurityValidated(
            securityContext: securityContext,
            sessionId: securityContext.sessionId,
          ),
        );
      },
      onUpgradeSecurity: () {
        _showSecurityUpgradeDialog(context);
      },
    );
  }

  Widget _buildCurrentStepContent(BuildContext context, CheckoutState state) {
    if (state is CheckoutStepInProgress) {
      return _buildStepContent(context, state.currentStep, state.stepData);
    } else if (state is CheckoutStepCompleted) {
      return _buildStepContent(context, state.currentStep, state.completedStepData);
    } else if (state is CheckoutValidationError) {
      return _buildStepContent(context, state.stepType, {});
    }

    return _buildStepContent(context, CheckoutStepType.cartReview, {});
  }

  Widget _buildStepContent(
    BuildContext context,
    CheckoutStepType stepType,
    Map<String, dynamic> stepData,
  ) {
    switch (stepType) {
      case CheckoutStepType.cartReview:
        return _buildCartReviewStep(context, stepData);
      case CheckoutStepType.shippingAddress:
        return _buildShippingAddressStep(context, stepData);
      case CheckoutStepType.billingAddress:
        return _buildBillingAddressStep(context, stepData);
      case CheckoutStepType.paymentMethod:
        return _buildPaymentMethodStep(context, stepData);
      case CheckoutStepType.reviewOrder:
        return _buildReviewOrderStep(context, stepData);
      case CheckoutStepType.confirmation:
        return _buildConfirmationStep(context, stepData);
    }
  }

  Widget _buildCartReviewStep(BuildContext context, Map<String, dynamic> stepData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Review Your Cart',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cart items would be loaded from cart service
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Cart items will be displayed here'),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentSession?.isGuest == true)
              GuestCheckoutWidget(
                sessionId: _currentSession!.sessionId,
                onGuestAccountCreated: (userId) {
                  // Handle guest account creation
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddressStep(BuildContext context, Map<String, dynamic> stepData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Address form will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingAddressStep(BuildContext context, Map<String, dynamic> stepData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Billing Address',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Billing address form will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep(BuildContext context, Map<String, dynamic> stepData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Payment method selection will be displayed here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewOrderStep(BuildContext context, Map<String, dynamic> stepData) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.review,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review Your Order',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_currentOrderSummary != null)
                  SecureOrderSummaryWidget(
                    orderSummary: _currentOrderSummary!,
                    sessionId: _currentSession?.sessionId ?? '',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(BuildContext context, Map<String, dynamic> stepData) {
    return const Center(
      child: Text('Confirmation step content'),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, CheckoutState state) {
    if (_currentOrderSummary == null) {
      return const SizedBox.shrink();
    }

    return OrderSummaryWidget(
      orderSummary: _currentOrderSummary!,
      showActions: false,
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, CheckoutState state) {
    CheckoutStepType currentStep = CheckoutStepType.cartReview;
    bool canProceed = true;

    if (state is CheckoutStepInProgress) {
      currentStep = state.currentStep;
    } else if (state is CheckoutStepCompleted) {
      currentStep = state.currentStep;
    }

    final isLastStep = currentStep == CheckoutStepType.reviewOrder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isFirstStep(currentStep))
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _navigateToPreviousStep(currentStep);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (!_isFirstStep(currentStep)) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        _proceedToNextStep(currentStep);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isLastStep ? 'Complete Order' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, CheckoutError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Checkout Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.failure.message,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _checkoutBloc.add(CheckoutErrorHandled(
                failure: state.failure,
                stepType: state.stepType,
              ));
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutView(BuildContext context, CheckoutTimeout state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_off,
            color: Colors.orange,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Session Expired',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your checkout session has expired due to inactivity.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _restartCheckout();
            },
            child: const Text('Restart Checkout'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationRequiredView(BuildContext context, CheckoutAuthenticationRequired state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            color: Colors.blue,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Required',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.reason,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to authentication
            },
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView(BuildContext context, CheckoutCompleted state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade700,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Order Completed!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order ID: ${state.orderId}',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you for your purchase!',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  void _handleStateChange(CheckoutState state) {
    if (state is CheckoutSessionCreated) {
      _currentSession = state.session;
      _currentSecurityContext = state.securityContext;
    } else if (state is CheckoutOrderSummaryLoaded) {
      _currentOrderSummary = state.orderSummary;
    } else if (state is CheckoutStepCompleted) {
      // Update session with completed step
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          completedSteps: [..._currentSession!.completedSteps, state.completedStep],
        );
      }
    }
  }

  void _proceedToNextStep(CheckoutStepType currentStep) {
    if (_currentSession == null) return;

    final nextStep = _getNextStep(currentStep);
    if (nextStep != null) {
      _checkoutBloc.add(
        CheckoutStepChanged(
          stepType: nextStep,
          sessionId: _currentSession!.sessionId,
        ),
      );
    } else {
      // Handle checkout completion
      _checkoutBloc.add(
        CheckoutCompleted(
          paymentMethodId: _currentSession!.savedPaymentMethodId ?? '',
          sessionId: _currentSession!.sessionId,
        ),
      );
    }
  }

  void _navigateToPreviousStep(CheckoutStepType currentStep) {
    if (_currentSession == null) return;

    final previousStep = _getPreviousStep(currentStep);
    if (previousStep != null) {
      _checkoutBloc.add(
        CheckoutStepChanged(
          stepType: previousStep,
          sessionId: _currentSession!.sessionId,
        ),
      );
    }
  }

  CheckoutStepType? _getNextStep(CheckoutStepType currentStep) {
    final steps = CheckoutStepDefinition.getStandardSteps();
    final currentIndex = steps.indexWhere((step) => step.type == currentStep);

    if (currentIndex != -1 && currentIndex < steps.length - 1) {
      return steps[currentIndex + 1].type;
    }

    return null;
  }

  CheckoutStepType? _getPreviousStep(CheckoutStepType currentStep) {
    final steps = CheckoutStepDefinition.getStandardSteps();
    final currentIndex = steps.indexWhere((step) => step.type == currentStep);

    if (currentIndex > 0) {
      return steps[currentIndex - 1].type;
    }

    return null;
  }

  bool _isFirstStep(CheckoutStepType currentStep) {
    final steps = CheckoutStepDefinition.getStandardSteps();
    return steps.first.type == currentStep;
  }

  void _restartCheckout() {
    if (widget.userId != null) {
      _checkoutBloc.add(
        CheckoutStarted(
          userId: widget.userId!,
          isGuest: widget.isGuest,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Help'),
        content: const Text(
          'This secure checkout process guides you through purchasing your items. '
          'Your information is encrypted and protected throughout the process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecurityUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Security'),
        content: const Text(
          'Would you like to enable additional security features for your checkout? '
          'This includes two-factor authentication and enhanced fraud protection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement security upgrade
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}