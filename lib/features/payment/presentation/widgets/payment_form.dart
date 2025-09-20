import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class PaymentForm extends StatefulWidget {
  final String userId;
  final String orderId;
  final double amount;
  final String currency;
  final void Function(PaymentModel)? onSuccess;
  final void Function(String)? onError;

  const PaymentForm({
    super.key,
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.currency,
    this.onSuccess,
    this.onError,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _saveCard = false;
  bool _isProcessing = false;
  String? _selectedCardId;
  List<CardModel> _savedCards = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  void _loadSavedCards() {
    context.read<PaymentBloc>().add(
      LoadUserCardsEvent(userId: widget.userId),
    );
  }

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCardId != null) {
      _processPaymentWithToken();
    } else {
      _processPaymentWithCard();
    }
  }

  void _processPaymentWithCard() {
    final cardInput = CardInputModel(
      cardNumber: _cardNumberController.text,
      expiryMonth: _expiryController.text.split('/')[0],
      expiryYear: _expiryController.text.split('/')[1],
      cvv: _cvvController.text,
      cardholderName: _cardholderNameController.text,
      saveCard: _saveCard,
    );

    setState(() => _isProcessing = true);

    context.read<PaymentBloc>().add(
      ProcessPaymentEvent(
        userId: widget.userId,
        orderId: widget.orderId,
        amount: widget.amount,
        currency: widget.currency,
        cardInput: cardInput,
        saveCard: _saveCard,
        isRecurring: false,
      ),
    );
  }

  void _processPaymentWithToken() {
    setState(() => _isProcessing = true);

    context.read<PaymentBloc>().add(
      ProcessPaymentWithTokenEvent(
        userId: widget.userId,
        orderId: widget.orderId,
        amount: widget.amount,
        currency: widget.currency,
        paymentToken: _selectedCardId!,
        isRecurring: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentOperationSuccess) {
          setState(() => _isProcessing = false);
          widget.onSuccess?.call(state.payment);
        } else if (state is PaymentError) {
          setState(() => _isProcessing = false);
          widget.onError?.call(state.message);
        } else if (state is CardsLoaded) {
          setState(() => _savedCards = state.cards);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSavedCardsSection(),
            if (_savedCards.isEmpty || _selectedCardId == null) ...[
              _buildCardDetailsSection(),
              _buildSaveCardOption(),
            ],
            _buildPaymentSummary(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardsSection() {
    if (_savedCards.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Cards',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._savedCards.map((card) => RadioListTile<String>(
          title: Text('${card.brand.name.toUpperCase()} ${card.maskedNumber}'),
          subtitle: Text('Expires ${card.expiryMonth}/${card.expiryYear}'),
          value: card.id,
          groupValue: _selectedCardId,
          onChanged: (value) {
            setState(() => _selectedCardId = value);
          },
        )),
        RadioListTile<String>(
          title: const Text('Use a new card'),
          value: '',
          groupValue: _selectedCardId,
          onChanged: (value) {
            setState(() => _selectedCardId = value);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 13) {
              return 'Invalid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter expiry date';
                  }
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Use MM/YY format';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter CVV';
                  }
                  if (value.length < 3) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardholderNameController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSaveCardOption() {
    return CheckboxListTile(
      title: const Text('Save card for future purchases'),
      value: _saveCard,
      onChanged: (value) {
        setState(() => _saveCard = value ?? false);
      },
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount:'),
              Text('${widget.currency} ${widget.amount.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Processing Fee:'),
              Text('${widget.currency} ${(widget.amount * 0.029 + 0.30).toStringAsFixed(2)}'),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.currency} ${(widget.amount * 1.029 + 0.30).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _submitPayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isProcessing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Processing...'),
              ],
            )
          : Text(
              'Pay ${widget.currency} ${(widget.amount * 1.029 + 0.30).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
    );
  }
}