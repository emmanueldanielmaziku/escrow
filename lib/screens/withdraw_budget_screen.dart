import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/budget_contract_model.dart';
import '../providers/user_provider.dart';
import '../services/budget_contract_service.dart';
import '../services/budget_payment_service.dart';
import '../utils/custom_snackbar.dart';

class WithdrawBudgetScreen extends StatefulWidget {
  final BudgetContractModel budget;

  const WithdrawBudgetScreen({
    super.key,
    required this.budget,
  });

  @override
  State<WithdrawBudgetScreen> createState() => _WithdrawBudgetScreenState();
}

class _WithdrawBudgetScreenState extends State<WithdrawBudgetScreen> {
  final _budgetPaymentService = BudgetPaymentService();
  final _budgetService = BudgetContractService();

  final _phoneNumberController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String? _selectedProvider;
  bool _showOverlay = false;
  bool _isInitiating = false;
  bool _isSuccess = false;

  // Color scheme — green
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _primaryLight = Color(0xFF388E3C);

  final Map<String, Map<String, String>> _paymentProviders = {
    'Mix by Yas': {
      'channel': 'TZ-TIGO-B2C',
      'logo': 'assets/icons/mixx.png',
    },
    'Airtel Money': {
      'channel': 'TZ-AIRTEL-B2C',
      'logo': 'assets/icons/airtel.png',
    },
  };

  @override
  void initState() {
    super.initState();
    // Default amount = full funded amount
    _amountController.text = widget.budget.fundedAmount.toStringAsFixed(2);

    _amountFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────
  String _getAmountDisplay() {
    final v = double.tryParse(_amountController.text.trim());
    if (v == null || v <= 0) {
      return widget.budget.fundedAmount.toStringAsFixed(2);
    }
    return v.toStringAsFixed(2);
  }

  /// Estimated fee (mirrors backend tiered fee)
  double _estimateFee(double amount) {
    if (amount <= 10000) return 1000;
    if (amount <= 100000) return 2000;
    if (amount <= 1000000) return 3000;
    if (amount <= 2500000) return 4000;
    return (amount * 0.005).roundToDouble();
  }

  // ──────────────────────────────────────────────
  //  Validation & submit
  // ──────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (_selectedProvider == null) {
      _snack('Please select a payment provider');
      return;
    }
    if (_phoneNumberController.text.trim().isEmpty) {
      _snack('Please enter your phone number');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount');
      return;
    }
    if (amount > widget.budget.fundedAmount) {
      _snack('Amount exceeds available funds (TSh ${widget.budget.fundedAmount.toStringAsFixed(2)})');
      return;
    }

    // Guard: non-negotiable contract term check (UI side)
    if (widget.budget.contractType == ContractType.nonNegotiable &&
        widget.budget.contractEndDate != null &&
        DateTime.now().isBefore(widget.budget.contractEndDate!)) {
      _snack(
        'Withdrawal not allowed until contract term ends: '
        '${_formatDate(widget.budget.contractEndDate!)}',
        error: true,
      );
      return;
    }

    await _proceedWithWithdrawal(amount);
  }

  Future<void> _proceedWithWithdrawal(double amount) async {
    setState(() => _isInitiating = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) throw Exception('User not found');

      String msisdn = _phoneNumberController.text.trim();
      if (!msisdn.startsWith('255')) {
        msisdn = msisdn.startsWith('0')
            ? '255${msisdn.substring(1)}'
            : '255$msisdn';
      }

      await _budgetPaymentService.initiateBudgetWithdrawal(
        budgetId: widget.budget.id,
        amount: amount,
        ownerId: user.id,
        msisdn: msisdn,
        channel: _paymentProviders[_selectedProvider]!['channel']!,
        recipientName: user.fullName.isNotEmpty ? user.fullName : 'Budget Owner',
        narration: 'Withdrawal from: ${widget.budget.title}',
      );

      if (mounted) {
        setState(() {
          _isInitiating = false;
          _showOverlay = true;
        });
        await _monitorWithdrawalStatus(amount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitiating = false);
        CustomSnackBar.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _monitorWithdrawalStatus(double amount) async {
    const timeout = Duration(seconds: 90);
    const interval = Duration(seconds: 3);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final budget = await _budgetService.getBudgetContractDetails(widget.budget.id);
        if (budget != null && budget.fundedAmount < widget.budget.fundedAmount) {
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
                  message: 'Withdrawal successful! Funds are on their way. 💸',
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

    if (mounted) {
      setState(() => _showOverlay = false);
      CustomSnackBar.show(
        context: context,
        message: 'Withdrawal is being processed. Funds will arrive shortly.',
        type: SnackBarType.info,
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    CustomSnackBar.show(
      context: context,
      message: msg,
      type: error ? SnackBarType.error : SnackBarType.error,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  // ──────────────────────────────────────────────
  //  Overlay
  // ──────────────────────────────────────────────
  Widget _buildOverlay() {
    return Material(
      color: Colors.white.withOpacity(0.6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSuccess) ...[
                const Icon(CupertinoIcons.checkmark_circle_fill, size: 80, color: _primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Withdrawal Successful!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Funds are on their way to your mobile money.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const CupertinoActivityIndicator(radius: 20, color: _primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Processing Withdrawal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait…',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fundedAmount = widget.budget.fundedAmount;
    final estimatedAmount = double.tryParse(_amountController.text.trim()) ?? fundedAmount;
    final fee = _estimateFee(estimatedAmount);
    final net = (estimatedAmount - fee).clamp(0.0, double.infinity);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Withdraw Funds',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
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
                // ── Header gradient ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_primaryColor, _primaryLight],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Container(
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
                          'Amount to Withdraw',
                          style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TSh ${_getAmountDisplay()}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available: TSh ${fundedAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Divider(height: 24),
                        // Fee breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Withdrawal fee:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('- TSh ${fee.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('You receive:', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                            Text('TSh ${net.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, color: _primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Mai Money',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Non-negotiable warning ──
                      if (widget.budget.contractType == ContractType.nonNegotiable &&
                          widget.budget.contractEndDate != null &&
                          DateTime.now().isBefore(widget.budget.contractEndDate!))
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Non-negotiable contract. Withdrawal allowed after:\n${_formatDate(widget.budget.contractEndDate!)}',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Amount input ──
                      const Text('Withdrawal Amount',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text('Enter how much you want to withdraw',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        prefix: const Icon(Icons.attach_money, color: _primaryColor),
                        prefixText: 'TSh ',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 28),

                      // ── Provider selection ──
                      const Text('Select Mobile Network',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text('Choose your mobile money network for payout',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ..._paymentProviders.entries.map((entry) {
                        final isSelected = _selectedProvider == entry.key;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => setState(() => _selectedProvider = entry.key),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _primaryColor : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? _primaryColor : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Center(child: Icon(Icons.check_circle, size: 14, color: _primaryColor))
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.key,
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.bold, color: _primaryColor)),
                                        Text('Channel: ${entry.value['channel']}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        entry.value['logo']!,
                                        scale: entry.value['logo'] == 'assets/icons/mixx.png' ? 12.0 : 23.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 28),

                      // ── Phone number ──
                      const Text('Phone Number',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text('Enter the phone number to receive funds',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _phoneNumberController,
                        focusNode: _phoneFocusNode,
                        hint: '0758376759',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefix: const Icon(Icons.phone_outlined, color: _primaryColor),
                        trailing: IconButton(
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              _phoneNumberController.text = data!.text!;
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.paste_outlined, color: _primaryColor),
                          tooltip: 'Paste',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 32),

                      // ── Submit button ──
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_showOverlay || _isInitiating) ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: _primaryColor.withOpacity(0.3),
                          ),
                          child: _isInitiating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CupertinoActivityIndicator(radius: 10, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Processing…',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                )
                              : const Text(
                                  'Withdraw Funds',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  // ──────────────────────────────────────────────
  //  Input field builder (reusable)
  // ──────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
    String? prefixText,
    Widget? trailing,
    void Function(String)? onChanged,
  }) {
    final focused = focusNode.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: focused ? _primaryColor : Colors.grey[300]!, width: focused ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: focused ? _primaryColor.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onTap: () => setState(() {}),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.all(18),
                border: InputBorder.none,
                prefixIcon: prefix,
                prefixText: prefixText,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

