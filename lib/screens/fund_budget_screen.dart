import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/budget_contract_model.dart';
import '../providers/user_provider.dart';
import '../services/budget_contract_service.dart';
import '../services/budget_payment_service.dart';
import '../services/budget_transaction_service.dart';
import '../utils/custom_snackbar.dart';
import '../utils/fee_calculator.dart';

class FundBudgetScreen extends StatefulWidget {
  final BudgetContractModel budget;

  const FundBudgetScreen({
    super.key,
    required this.budget,
  });

  @override
  State<FundBudgetScreen> createState() => _FundBudgetScreenState();
}

class _FundBudgetScreenState extends State<FundBudgetScreen> {
  final _budgetPaymentService = BudgetPaymentService();
  final _budgetTransactionService = BudgetTransactionService();
  final _phoneNumberController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String? _selectedProvider;
  bool _showOverlay = false;
  bool _isInitiatingPayment = false;
  bool _isSuccess = false;
  String? _currentDepositId;

  final _budgetService = BudgetContractService();

  final Map<String, Map<String, String>> _paymentProviders = {
    'Mix by Yas': {
      'channel': 'TZ-TIGO-C2B',
      'logo': 'assets/icons/mixx.png',
    },
    'Airtel Money': {
      'channel': 'TZ-AIRTEL-C2B',
      'logo': 'assets/icons/airtel.png',
    },
  };

  @override
  void initState() {
    super.initState();
    // Set default amount to remaining amount needed
    final remainingAmount = widget.budget.amount - widget.budget.fundedAmount;
    _amountController.text = remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _getAmountToDisplay() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      final remainingAmount = widget.budget.amount - widget.budget.fundedAmount;
      return remainingAmount.toStringAsFixed(2);
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      final remainingAmount = widget.budget.amount - widget.budget.fundedAmount;
      return remainingAmount.toStringAsFixed(2);
    }
    return amount.toStringAsFixed(2);
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _phoneNumberController.text = clipboardData!.text!;
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedProvider == null) {
      CustomSnackBar.show(
        context: context,
        message: 'Please select a payment provider',
        type: SnackBarType.error,
      );
      return;
    }

    if (_phoneNumberController.text.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please enter your phone number',
        type: SnackBarType.error,
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please enter an amount',
        type: SnackBarType.error,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      CustomSnackBar.show(
        context: context,
        message: 'Please enter a valid amount',
        type: SnackBarType.error,
      );
      return;
    }

    final remainingAmount = widget.budget.amount - widget.budget.fundedAmount;
    if (amount > remainingAmount) {
      CustomSnackBar.show(
        context: context,
        message: 'Amount cannot exceed remaining amount (TSh ${remainingAmount.toStringAsFixed(2)})',
        type: SnackBarType.error,
      );
      return;
    }

    _proceedWithPayment(amount);
  }

  Future<void> _proceedWithPayment(double amount) async {
    setState(() {
      _isInitiatingPayment = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) throw Exception('User not found');

      // Format phone to international (255XXXXXXXXX)
      String formattedMsisdn = _phoneNumberController.text.trim();
      if (!formattedMsisdn.startsWith('255')) {
        formattedMsisdn = formattedMsisdn.startsWith('0')
            ? '255${formattedMsisdn.substring(1)}'
            : '255$formattedMsisdn';
      }

      // Call the new budget-specific endpoint
      final result = await _budgetPaymentService.initiateBudgetDeposit(
        budgetId: widget.budget.id,
        amount: amount,
        ownerId: user.id,
        msisdn: formattedMsisdn,
        channel: _paymentProviders[_selectedProvider]!['channel']!,
        narration: 'Funding budget: ${widget.budget.title}',
      );

      _currentDepositId = result['data']?['depositId'] as String?;

      if (mounted) {
        setState(() {
          _isInitiatingPayment = false;
          _showOverlay = true;
        });
        await _monitorDepositStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitiatingPayment = false);
        CustomSnackBar.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _monitorDepositStatus() async {
    const timeout = Duration(seconds: 90);
    const interval = Duration(seconds: 3);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        // Poll Firestore budget_contracts for status change
        final budget = await _budgetService.getBudgetContractDetails(widget.budget.id);

        if (budget?.status == BudgetContractStatus.active ||
            (budget != null && budget.fundedAmount > widget.budget.fundedAmount)) {
          if (mounted) {
            setState(() => _isSuccess = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              setState(() => _showOverlay = false);
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                Navigator.pop(context);
                CustomSnackBar.show(
                  context: context,
                  message: 'Budget funded successfully! 🎉',
                  type: SnackBarType.success,
                );
              }
            }
          }
          return;
        }
      } catch (_) {}

      await Future.delayed(interval);
    }

    // Timeout — user can check later; the callback will still update the budget
    if (mounted) {
      setState(() => _showOverlay = false);
      CustomSnackBar.show(
        context: context,
        message: 'Payment is being processed. Your budget will update shortly.',
        type: SnackBarType.info,
      );
    }
  }

  Widget _buildOverlay() {
    return Material(
      color: const Color.fromARGB(255, 238, 238, 238).withOpacity(0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSuccess) ...[
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: 80,
                  color: Color.fromARGB(255, 36, 138, 2),
                ),
                const SizedBox(height: 20),
                Text(
                  'Budget Funded Successfully!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget is now active',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const CupertinoActivityIndicator(
                  radius: 20,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Processing Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Fund Budget',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green, Colors.green, Colors.green],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      // Budget Amount Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Amount to Add',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TSh ${_getAmountToDisplay()}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current: TSh ${widget.budget.fundedAmount.toStringAsFixed(2)} / TSh ${widget.budget.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Mai Money',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Input Section
                      const Text(
                        'Amount to Add',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the amount you want to add to this budget',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _amountFocusNode.hasFocus
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[300]!,
                            width: _amountFocusNode.hasFocus ? 2 : 1,
                          ),
                          boxShadow: _amountFocusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: const TextStyle(fontSize: 16),
                          onTap: () {
                            setState(() {});
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            contentPadding: EdgeInsets.all(20),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: Color(0xFF2E7D32),
                            ),
                            prefixText: 'TSh ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Section Title
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferred payment provider',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment Provider Cards
                      ..._paymentProviders.entries.map((entry) {
                        final isSelected = _selectedProvider == entry.key;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedProvider = entry.key;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.white : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF2E7D32)
                                              .withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Radio Button
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),

                                  // Provider Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Channel: ${entry.value['channel']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Provider Logo
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        entry.value['logo']!,
                                        scale: entry.value['logo'] ==
                                                "assets/icons/mixx.png"
                                            ? 12.0
                                            : entry.value['logo'] ==
                                                    "assets/icons/airtel.png"
                                                ? 23.0
                                                : 10.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      // Phone Number Section
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your phone number for payment verification',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _phoneFocusNode.hasFocus
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[300]!,
                            width: _phoneFocusNode.hasFocus ? 2 : 1,
                          ),
                          boxShadow: _phoneFocusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneNumberController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(fontSize: 16),
                                onTap: () {
                                  setState(() {});
                                },
                                onChanged: (value) {
                                  setState(() {});
                                },
                                decoration: const InputDecoration(
                                  hintText: '0758376759',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  contentPadding: EdgeInsets.all(20),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                onPressed: _handlePaste,
                                icon: const Icon(
                                  Icons.paste_outlined,
                                  color: Color(0xFF2E7D32),
                                ),
                                tooltip: 'Paste from clipboard',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_showOverlay || _isInitiatingPayment)
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isInitiatingPayment
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    CupertinoActivityIndicator(
                                      radius: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Initiating Payment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Submit Fund Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showOverlay) _buildOverlay(),
      ],
    );
  }
}

