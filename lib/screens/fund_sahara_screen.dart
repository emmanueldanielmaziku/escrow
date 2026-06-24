import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/sahara_contract_model.dart';
import '../providers/user_provider.dart';
import '../services/sahara_contract_service.dart';
import '../services/sahara_payment_service.dart';
import '../services/network_service.dart';
import '../utils/custom_snackbar.dart';

class FundSaharaScreen extends StatefulWidget {
  final SaharaContractModel sahara;

  const FundSaharaScreen({
    super.key,
    required this.sahara,
  });

  @override
  State<FundSaharaScreen> createState() => _FundSaharaScreenState();
}

class _FundSaharaScreenState extends State<FundSaharaScreen> {
  final _saharaPaymentService = SaharaPaymentService();
  final _saharaService = SaharaContractService();
  final _phoneNumberController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  bool _showOverlay = false;
  bool _isInitiatingPayment = false;
  bool _isSuccess = false;
  bool _isFullyFunded = false;
  String _mobileProvider = 'Azampesa';
  SaharaContractStatus? _baselineStatus;
  double _baselineFundedAmount = 0;

  static const Map<String, String> _mobileProviders = {
    'Airtel': 'Airtel',
    'Tigo': 'Tigo',
    'Halopesa': 'Halopesa',
    'Azampesa': 'Azampesa',
    'Mpesa': 'Mpesa',
  };

  double get _maxAmount => widget.sahara.amount - widget.sahara.fundedAmount;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = _maxAmount.toStringAsFixed(2);
    NetworkService().startMonitoring();
  }

  String _getAmountToDisplay() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      final remainingAmount = widget.sahara.amount - widget.sahara.fundedAmount;
      return remainingAmount.toStringAsFixed(2);
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      final remainingAmount = widget.sahara.amount - widget.sahara.fundedAmount;
      return remainingAmount.toStringAsFixed(2);
    }
    return amount.toStringAsFixed(2);
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _phoneNumberController.text = clipboardData!.text!;
      setState(() {
        _mobileProvider = _detectProviderFromPhone(_phoneNumberController.text);
      });
    }
  }

  Future<void> _handleSubmit() async {
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

    final remainingAmount = widget.sahara.amount - widget.sahara.fundedAmount;
    if (amount > remainingAmount) {
      CustomSnackBar.show(
        context: context,
        message:
            'Amount cannot exceed remaining amount (TSh ${remainingAmount.toStringAsFixed(2)})',
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

      final String rawMsisdn = _phoneNumberController.text.trim();
      final String msisdn = _formatPhoneNumber(rawMsisdn, _mobileProvider);

      final current = await _saharaService.getSaharaContractDetails(widget.sahara.id);
      _baselineStatus = current?.status;
      _baselineFundedAmount = current?.fundedAmount ?? widget.sahara.fundedAmount;

      final response = await _saharaPaymentService.initiateSaharaDeposit(
        budgetId: widget.sahara.id,
        amount: amount,
        ownerId: user.id,
        msisdn: msisdn,
        provider: _mobileProvider,
        narration: 'Funding sahara: ${widget.sahara.title}',
      );

      final inner = response['data'];
      final apiStatus = inner is Map ? inner['status']?.toString() : null;

      if (apiStatus == 'FAILED') {
        if (mounted) {
          setState(() => _isInitiatingPayment = false);
          CustomSnackBar.show(
            context: context,
            message: response['message']?.toString() ?? 'Payment initiation failed. Please try again.',
            type: SnackBarType.error,
          );
        }
        return;
      }

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

  Future<void> _monitorDepositStatus() async {
    const interval = Duration(seconds: 3);

    while (true) {
      try {
        final sahara =
            await _saharaService.getSaharaContractDetails(widget.sahara.id);

        if (sahara == null) {
          await Future.delayed(interval);
          continue;
        }

        final fundedIncreased = sahara.fundedAmount > _baselineFundedAmount;
        final statusUpgraded = _baselineStatus == SaharaContractStatus.unfunded &&
            (sahara.status == SaharaContractStatus.inProgress ||
             sahara.status == SaharaContractStatus.active);

        if (fundedIncreased || statusUpgraded) {
          if (mounted) {
            setState(() {
              _isSuccess = true;
              _isFullyFunded = sahara.status == SaharaContractStatus.active;
            });
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              setState(() => _showOverlay = false);
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                Navigator.pop(context);
                CustomSnackBar.show(
                  context: context,
                  message: 'Sahara funded successfully! 🎉',
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
                  'Sahara Funded Successfully!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFullyFunded
                      ? 'Sahara is now active'
                      : 'Deposit successful',
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
              'Fund Sahara',
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
                      // Sahara Amount Card
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
                              'Current: TSh ${widget.sahara.fundedAmount.toStringAsFixed(2)} / TSh ${widget.sahara.amount.toStringAsFixed(2)}',
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
                      // Mobile Provider Dropdown
                      const Text(
                        'Mobile Provider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      const Text(
                        'A payment request will be sent to your Azampesa app. Open the app and approve it to complete the payment.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

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
                        'Enter the amount you want to add to this sahara',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A deposit fee of 0.8% will be applied.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
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
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          style: const TextStyle(fontSize: 16),
                          onTap: () {
                            setState(() {});
                          },
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
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
                                  setState(() {
                                    _mobileProvider =
                                        _detectProviderFromPhone(value);
                                  });
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
                                    color: Color(0xFF2E7D32),
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
        StreamBuilder<bool>(
          stream: NetworkService().onConnectivityChanged,
          initialData: true,
          builder: (context, snapshot) {
            final connected = snapshot.data ?? true;
            if (connected) return const SizedBox.shrink();
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  color: Colors.orange.shade700,
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No internet connection. Payment may fail.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
