import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/contract_model.dart';
import '../providers/user_provider.dart';
import '../services/deposit_service.dart';
import '../services/contract_service.dart';
import '../utils/custom_snackbar.dart';

class FundContractScreen extends StatefulWidget {
  final ContractModel contract;

  const FundContractScreen({
    super.key,
    required this.contract,
  });

  @override
  State<FundContractScreen> createState() => _FundContractScreenState();
}

class _FundContractScreenState extends State<FundContractScreen> {
  final _depositService = DepositService();
  final _paymentMessageController = TextEditingController();
  String? _selectedProvider;
  bool _isLoading = false;
 
  final _contractService = ContractService();

  final Map<String, Map<String, String>> _paymentProviders = {
    'Mix by Yas Agent': {
      'number': '864706',
      'logo': 'assets/icons/mixx.png',
    },
    'Selcom Agent': {
      'number': '61135943',
      'logo': 'assets/icons/selcom.png',
    },
    'Halopesa': {
      'number': '678387',
      'logo': 'assets/icons/halopesa.png',
    },
    'NMB Lipa Namba': {
      'number': '21262098',
      'logo': 'assets/icons/nmb.webp',
    },
  };

  @override
  void dispose() {
    _paymentMessageController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _paymentMessageController.text = clipboardData!.text!;
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

    if (_paymentMessageController.text.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Please paste the payment confirmation message',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) {
        throw Exception('User not found');
      }

      await _depositService.createDeposit(
        contractId: widget.contract.id,
        userId: user.id,
        provider: _selectedProvider!,
        contractFund: widget.contract.reward.toString(),
        controlNumber: _paymentProviders[_selectedProvider]!['number']!,
        paymentMessage: _paymentMessageController.text,
      );

      await _contractService.updateContractStatus(
        widget.contract.id,
        'active',
        currentUserName: user.fullName,
      );

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Your payment request has been sent for approval',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error submitting payment: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fund Contract',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract Amount Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contract Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'TSh ${widget.contract.reward.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title/Instruction
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14.0,
                  color: Colors.grey[700],
                ),
                children: [
                  TextSpan(
                    text: 'Gateway Name: ',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                      text: 'Mai Money',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.green[500],
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 5.0),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14.0,
                  color: Colors.grey[700],
                ),
                children: [
                  TextSpan(
                    text: 'Note: ',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                      text: 'Please choose your payment gateway.',
                      style: TextStyle(
                        fontSize: 14.0,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Provider Cards
            ..._paymentProviders.entries.map((entry) {
              final isSelected = _selectedProvider == entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedProvider = entry.key;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.value['number'] ?? '',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Image.asset(entry.value['logo']!,
                                  scale: entry.value['logo'] ==
                                          "assets/icons/mixx.png"
                                      ? 12.0
                                      : entry.value['logo'] ==
                                              "assets/icons/nmb.webp"
                                          ? 10.0
                                          : entry.value['logo'] ==
                                                  "assets/icons/selcom.png"
                                              ? 5.0
                                              : entry.value['logo'] ==
                                                      "assets/icons/halopesa.png"
                                                  ? 12.0
                                                  : 10.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 15.0),

            // Instruction Text
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14.0,
                  color: Colors.grey[700],
                ),
                children: [
                  TextSpan(
                    text: 'Note: ',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                      text:
                          'After completing the payment, please copy the payment confirmation SMS from your phone and paste it below.',
                      style: TextStyle(
                        fontSize: 14.0,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Message Input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paymentMessageController,
                      maxLines: 4,
                      style: TextStyle(fontSize: 14.0),
                      decoration: const InputDecoration(
                        hintText:
                            'Eg: 0604135KT Confirmed. You have sent TZS 2,000.00 to EMMANUEL DANIEL MAZIKU - M-Pesa (0758376759) on 2025-06-04 17:42:02. TIPS reference CF44ID9ZH8Y. Help 0800 714 888/ 0800 784 888',
                        hintStyle:
                            TextStyle(fontSize: 14.0, color: Colors.grey),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _handlePaste,
                    icon: const Icon(Icons.paste_outlined),
                    tooltip: 'Paste from clipboard',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Fund Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
