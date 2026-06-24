import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/sahara_contract_model.dart';
import '../models/sahara_transaction_model.dart';
import '../providers/user_provider.dart';
import '../services/sahara_contract_service.dart';
import '../services/sahara_payment_service.dart';
import '../services/sahara_transaction_service.dart';
import '../services/payment_service.dart';
import '../utils/custom_snackbar.dart';

class WithdrawSaharaScreen extends StatefulWidget {
  final SaharaContractModel sahara;

  const WithdrawSaharaScreen({
    super.key,
    required this.sahara,
  });

  @override
  State<WithdrawSaharaScreen> createState() => _WithdrawSaharaScreenState();
}

class _WithdrawSaharaScreenState extends State<WithdrawSaharaScreen> {
  final _saharaPaymentService = SaharaPaymentService();
  final _saharaService = SaharaContractService();
  final _transactionService = SaharaTransactionService();

  final _phoneNumberController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _mobileProvider = 'Azampesa';
  bool _showOverlay = false;
  bool _isInitiating = false;
  bool _isSuccess = false;
  String? _withdrawalId;

  // Color scheme — green
  static const Color _primaryColor = Color(0xFF2E7D32);
  static const Color _primaryLight = Color(0xFF388E3C);

  // Snippe supported banks (code -> display name)
  static const Map<String, String> _mobileProviders = {
    'Airtel': 'Airtel',
    'Tigo': 'Tigo',
    'Halopesa': 'Halopesa',
    'Azampesa': 'Azampesa',
    'Mpesa': 'Mpesa',
  };

  double get _maxAmount => widget.sahara.fundedAmount;

  @override
  void initState() {
    super.initState();
    // Default amount = full funded amount
    _amountController.text = _maxAmount.toStringAsFixed(2);

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
      return widget.sahara.fundedAmount.toStringAsFixed(2);
    }
    return v.toStringAsFixed(2);
  }

  // ──────────────────────────────────────────────
  //  Validation & submit
  // ──────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (_phoneNumberController.text.trim().isEmpty) {
      _snack('Please enter your phone number');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount');
      return;
    }
    if (amount > widget.sahara.fundedAmount) {
      _snack(
          'Amount exceeds available funds (TSh ${widget.sahara.fundedAmount.toStringAsFixed(2)})');
      return;
    }

    // Guard: non-negotiable contract term check (UI side)
    if (widget.sahara.contractType == ContractType.nonNegotiable &&
        widget.sahara.contractEndDate != null &&
        DateTime.now().isBefore(widget.sahara.contractEndDate!)) {
      _snack(
        'Withdrawal not allowed until contract term ends: '
        '${_formatDate(widget.sahara.contractEndDate!)}',
        error: true,
      );
      return;
    }

    final confirmed = await _showWithdrawalConfirmation(amount);
    if (confirmed == true && mounted) {
      await _proceedWithWithdrawal(amount);
    }
  }

  Future<bool?> _showWithdrawalConfirmation(double amount) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return false;

    final String msisdn = _phoneNumberController.text.trim();
    final provider = _mobileProvider;
    final providerLabel = _mobileProviders[provider] ?? provider;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 24, color: Colors.white),
        ),
      ),
    );

    String? recipientName;
    try {
      final paymentService = PaymentService();
      final lookupResult = await paymentService.nameLookup(
        accountNumber: msisdn,
        provider: provider,
        channel: 'mobile',
        authToken: user.id,
      );
      final lookupData = lookupResult['data'] as Map<String, dynamic>?;
      recipientName = _extractLookupName(lookupData?['lookupResult']);
    } catch (_) {
      recipientName = null;
    }

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return null;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _NameLookupConfirmationSheet(
        amount: amount,
        msisdn: msisdn,
        providerLabel: providerLabel,
        recipientName: recipientName,
        primaryColor: _primaryColor,
        title: 'Confirm Withdrawal',
      ),
    );
  }

  Future<void> _proceedWithWithdrawal(double amount) async {
    setState(() => _isInitiating = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) throw Exception('User not found');

      final String rawMsisdn = _phoneNumberController.text.trim();
      final String msisdn = _formatPhoneNumber(rawMsisdn, _mobileProvider);
      final provider = _mobileProvider;

      final response = await _saharaPaymentService.initiateSaharaWithdrawal(
        budgetId: widget.sahara.id,
        amount: amount,
        ownerId: user.id,
        msisdn: msisdn,
        channel: 'mobile',
        recipientName:
            user.fullName.isNotEmpty ? user.fullName : 'Sahara Owner',
        narration: 'Withdrawal from: ${widget.sahara.title}',
        provider: provider,
      );

      final withdrawalId = response['data']?['withdrawalId'] as String?;
      _withdrawalId = withdrawalId;

      if (mounted) {
        setState(() {
          _isInitiating = false;
          _showOverlay = true;
        });
        await _monitorWithdrawalStatus(amount, withdrawalId: _withdrawalId);
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

  String _formatPhoneNumber(String phone, String provider) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (provider == 'Azampesa') {
      if (digits.startsWith('255')) {
        digits = '1${digits.substring(3)}';
      } else if (digits.startsWith('0')) {
        digits = '1${digits.substring(1)}';
      } else if (!digits.startsWith('1')) {
        digits = '1$digits';
      }
    } else {
      if (digits.startsWith('0')) digits = '255${digits.substring(1)}';
      if (!digits.startsWith('255')) digits = '255$digits';
    }
    return digits;
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _phoneNumberController.text = data!.text!;
      setState(() {
        _mobileProvider = _detectProviderFromPhone(_phoneNumberController.text);
      });
    }
  }

  String _detectProviderFromPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255')) {
      digits = '0${digits.substring(3)}';
    }

    if (digits.startsWith('0')) {
      if (digits.length >= 3) {
        final prefix = digits.substring(0, 3);
        if (['074', '075', '076'].contains(prefix)) return 'Mpesa';
        if (['065', '067', '071'].contains(prefix)) return 'Tigo';
        if (['068', '069', '078'].contains(prefix)) return 'Airtel';
        if (['061', '062'].contains(prefix)) return 'Halopesa';
      }
      final trimmed = digits.substring(1);
      if (trimmed.startsWith('16') || trimmed.startsWith('17')) {
        return 'Azampesa';
      }
    } else {
      if (digits.startsWith('16') || digits.startsWith('17')) {
        return 'Azampesa';
      }
    }

    return _mobileProvider;
  }

  Future<void> _monitorWithdrawalStatus(double amount,
      {String? withdrawalId}) async {
    const timeout = Duration(seconds: 90);
    const interval = Duration(seconds: 3);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final sahara =
            await _saharaService.getSaharaContractDetails(widget.sahara.id);
        if (sahara != null &&
            sahara.fundedAmount < widget.sahara.fundedAmount) {
          _showSuccess();
          return;
        }
      } catch (_) {}

      if (withdrawalId != null) {
        try {
          final tx = await _transactionService.pollTransactionStatus(
            budgetId: widget.sahara.id,
            transactionId: withdrawalId,
            isDeposit: false,
            timeout: const Duration(seconds: 2),
            interval: const Duration(milliseconds: 500),
          );
          if (tx != null) {
            if (tx.status == SaharaTransactionStatus.completed) {
              _showSuccess();
              return;
            } else if (tx.status == SaharaTransactionStatus.failed) {
              _showFailure();
              return;
            }
          }
        } catch (_) {}
      }

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

  void _showSuccess() {
    if (!mounted) return;
    setState(() => _isSuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showOverlay = false);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context);
            CustomSnackBar.show(
              context: context,
              message: 'Withdrawal successful! Funds are on their way.',
              type: SnackBarType.success,
            );
          }
        });
      }
    });
  }

  void _showFailure() {
    if (!mounted) return;
    setState(() => _showOverlay = false);
    CustomSnackBar.show(
      context: context,
      message: 'Withdrawal failed. Please try again.',
      type: SnackBarType.error,
    );
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

  String? _extractLookupName(dynamic lookupResult) {
    if (lookupResult == null) return null;
    if (lookupResult is Map) {
      return lookupResult['name']?.toString() ??
          lookupResult['accountName']?.toString() ??
          lookupResult['fullName']?.toString();
    }
    return null;
  }

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
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    size: 80, color: _primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Withdrawal Successful!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Funds are on their way to your mobile money.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const CupertinoActivityIndicator(
                    radius: 20, color: _primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Processing Withdrawal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor),
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
    final fundedAmount = widget.sahara.fundedAmount;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Withdraw Funds',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
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
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TSh ${_getAmountDisplay()}',
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available: TSh ${fundedAmount.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Divider(height: 24),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('You will receive:',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600)),
                            Text('TSh ${_getAmountDisplay()}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Mai Money',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor),
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
                      if (widget.sahara.contractType ==
                              ContractType.nonNegotiable &&
                          widget.sahara.contractEndDate != null &&
                          DateTime.now()
                              .isBefore(widget.sahara.contractEndDate!))
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
                              Icon(Icons.lock_clock,
                                  color: Colors.orange[700], size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Non-negotiable contract. Withdrawal allowed after:\n${_formatDate(widget.sahara.contractEndDate!)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Amount input ──
                      const Text('Withdrawal Amount',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text('Enter how much you want to withdraw',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        prefix: const Icon(Icons.attach_money,
                            color: _primaryColor),
                        prefixText: 'TSh ',
                        onChanged: (_) {
                          final parsed =
                              double.tryParse(_amountController.text);
                          if (parsed != null && parsed > _maxAmount) {
                            _amountController.text =
                                _maxAmount.toStringAsFixed(2);
                            _amountController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _amountController.text.length),
                            );
                          }
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Provider selection ──
                      const Text('Mobile Provider',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text(
                        'Select the mobile money provider',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _mobileProvider,
                        items: _mobileProviders.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _mobileProvider = v!),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Phone number ──
                      const Text('Phone Number',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor)),
                      const SizedBox(height: 8),
                      Text('Enter the phone number to receive funds',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _phoneNumberController,
                        focusNode: _phoneFocusNode,
                        hint: '0758376759',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        prefix: const Icon(Icons.phone_outlined,
                            color: _primaryColor),
                        trailing: IconButton(
                          onPressed: _handlePaste,
                          icon: const Icon(Icons.paste_outlined,
                              color: _primaryColor),
                          tooltip: 'Paste',
                        ),
                        onChanged: (value) => setState(() {
                          _mobileProvider = _detectProviderFromPhone(value);
                        }),
                      ),

                      const SizedBox(height: 32),

                      // ── Submit button ──
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_showOverlay || _isInitiating)
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: _primaryColor.withOpacity(0.3),
                          ),
                          child: _isInitiating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CupertinoActivityIndicator(
                                        radius: 10, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Processing…',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                )
                              : const Text(
                                  'Withdraw Funds',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
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
        border: Border.all(
            color: focused ? _primaryColor : Colors.grey[300]!,
            width: focused ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: focused
                ? _primaryColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
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

class _NameLookupConfirmationSheet extends StatelessWidget {
  final double amount;
  final String msisdn;
  final String providerLabel;
  final String? recipientName;
  final Color primaryColor;
  final String title;

  const _NameLookupConfirmationSheet({
    required this.amount,
    required this.msisdn,
    required this.providerLabel,
    required this.recipientName,
    required this.primaryColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(height: 60),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.info_outline,
                          color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('Amount', 'TSh ${amount.toStringAsFixed(2)}'),
                      const Divider(height: 16),
                      _buildRow('Phone', msisdn),
                      const Divider(height: 16),
                      _buildRow('Provider', providerLabel),
                      const Divider(height: 16),
                      if (recipientName != null)
                        _buildRow('Recipient', recipientName!,
                            valueColor: primaryColor)
                      else
                        _buildRow('Recipient', 'Not available',
                            valueColor: Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text('Confirm',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
