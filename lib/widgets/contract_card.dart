// ignore_for_file: use_build_context_synchronously

import 'package:escrow_app/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contract_model.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/contract_service.dart';
import '../services/payment_service.dart';
import '../services/provider_service.dart';
import '../models/provider_model.dart';
import 'contract_summary_bottom_sheet.dart';

class ContractCard extends StatefulWidget {
  final ContractModel contract;
  final VoidCallback? onFundContract;
  final VoidCallback? onRequestWithdrawal;
  final VoidCallback? onDeleteContract;
  final VoidCallback? onAcceptInvitation;
  final Function(String)? onTerminateContract;
  final VoidCallback? onConfirmWithdrawal;
  final VoidCallback? onDeclineWithdrawal;
  final VoidCallback? onApproveTermination;
  final bool showDescription;

  const ContractCard({
    super.key,
    required this.contract,
    this.onFundContract,
    this.onRequestWithdrawal,
    this.onDeleteContract,
    this.onAcceptInvitation,
    this.onTerminateContract,
    this.onConfirmWithdrawal,
    this.onDeclineWithdrawal,
    this.onApproveTermination,
    this.showDescription = true,
  });

  @override
  State<ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<ContractCard> {
  bool _isExpanded = false;
  bool _isDescriptionExpanded = false;
  bool _showTerminationReasonInput = false;
  final TextEditingController _terminationReasonController =
      TextEditingController();

  // Fund collection state
  String _mobileProvider = 'Azampesa';
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _showConfirmation = false;
  bool _isTransferring = false;

  static const Map<String, String> _mobileProviders = {
    'Azampesa': 'Azampesa',
  };
  List<ProviderModel> _providers = [];
  final _providerService = ProviderService();

  @override
  void initState() {
    super.initState();
    _terminationReasonController.addListener(_onTerminationReasonChanged);
    _loadProviders();
  }

  @override
  void dispose() {
    _terminationReasonController.removeListener(_onTerminationReasonChanged);
    _terminationReasonController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final list = await _providerService.fetchProviders();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _providers = list;
          _mobileProvider = list.first.name;
        });
      }
    } catch (_) {}
  }

  void _onTerminationReasonChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'TSh ',
      decimalDigits: 0,
      locale: 'en_US',
    );

    final isRemitter = widget.contract.remitterId == userProvider.user?.id;
    final isBeneficiary =
        widget.contract.beneficiaryId == userProvider.user?.id;
    Widget remitterAvatar = RandomAvatar(widget.contract.remitterName ?? 'User',
        trBackground: true, height: 50, width: 50);
    Widget beneficiaryAvatar = RandomAvatar(
        widget.contract.beneficiaryName ?? 'User',
        trBackground: true,
        height: 50,
        width: 50);
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 0.5, color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            ContractModel.getStatusColor(widget.contract.status)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: ContractModel.getStatusColor(
                                widget.contract.status),
                            width: 0.5),
                      ),
                      child: Text(
                        ContractModel.getStatusText(widget.contract.status),
                        style: TextStyle(
                          color: ContractModel.getStatusColor(
                              widget.contract.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 0.5),
                      ),
                      child: Text(
                        currencyFormat.format(widget.contract.reward),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                widget.contract.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.showDescription) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contract.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded
                            ? null
                            : TextOverflow.ellipsis,
                      ),
                      if (!_isDescriptionExpanded &&
                          widget.contract.description.length > 100)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDescriptionExpanded = true;
                            });
                          },
                          child: Text(
                            '...more',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_isDescriptionExpanded)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDescriptionExpanded = false;
                            });
                          },
                          child: Text(
                            '...less',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Created Date
              Text(
                'Created ${DateFormat('MMM d, y').format(widget.contract.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Participants section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Remitter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remitter',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: remitterAvatar,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.contract.remitterName ??
                                      'Not assigned',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    // Beneficiary
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beneficiary',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: beneficiaryAvatar,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.contract.beneficiaryName ??
                                        'Not assigned',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons - Only show when expanded
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                _buildActionButtons(theme, isRemitter, isBeneficiary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      ThemeData theme, bool isRemitter, bool isBeneficiary) {
    if (widget.contract.status == 'non-active') {
      if (isRemitter && widget.contract.role == 'Remitter') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onDeleteContract,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                label: const Text('Delete Contract',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        );
      } else if (isBeneficiary && widget.contract.role == 'Beneficiary') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onDeleteContract,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                label: const Text('Delete Contract',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        );
      } else if (isBeneficiary && widget.contract.role == 'Remitter') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onAcceptInvitation,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Accept Invitation'),
          ),
        );
      } else if (isRemitter && widget.contract.role == 'Beneficiary') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onAcceptInvitation,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Accept Invitation'),
          ),
        );
      }
    } else if (widget.contract.status == 'unfunded') {
      if (isRemitter && widget.contract.role == 'Beneficiary') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onFundContract,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined,
                size: 18, color: Colors.white),
            label: const Text('Fund Contract'),
          ),
        );
      } else if (isRemitter && widget.contract.role == 'Remitter') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onFundContract,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined,
                size: 18, color: Colors.white),
            label: const Text('Fund Contract'),
          ),
        );
      } else if (isBeneficiary && widget.contract.role == 'Remitter') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.hourglass_empty, size: 18),
            label: const Text('Wait for contract to be funded'),
          ),
        );
      } else if (isBeneficiary && widget.contract.role == 'Beneficiary') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.hourglass_empty, size: 18),
            label: const Text('Wait for contract to be funded'),
          ),
        );
      }
    } else if (widget.contract.status == 'active') {
      if (isRemitter) {
        if (_showTerminationReasonInput) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termination Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _terminationReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason for termination...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red[400]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showTerminationReasonInput = false;
                                _terminationReasonController.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _terminationReasonController.text
                                    .trim()
                                    .isNotEmpty
                                ? () {
                                    widget.onTerminateContract?.call(
                                        _terminationReasonController.text
                                            .trim());
                                    setState(() {
                                      _showTerminationReasonInput = false;
                                      _terminationReasonController.clear();
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTerminationReasonInput = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('Terminate Contract'),
                ),
              ),
              const SizedBox(height: 8),
              _buildViewReceiptButton(),
            ],
          );
        }
      } else if (isBeneficiary) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onRequestWithdrawal?.call(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.money_outlined, size: 18),
                label: const Text('Request Withdrawal'),
              ),
            ),
            const SizedBox(height: 8),
            _buildViewReceiptButton(),
          ],
        );
      }
    } else if (widget.contract.status == 'withdraw') {
      if (isRemitter) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onConfirmWithdrawal?.call(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text('Confirm'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onDeclineWithdrawal?.call(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text('Decline Request'),
              ),
            ),
          ],
        );
      } else if (isBeneficiary) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.hourglass_empty, size: 18),
            label: const Text('Waiting for approval'),
          ),
        );
      }
    } else if (widget.contract.status == 'completed') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Contract closed successfully'),
            ),
          ),
          if (isBeneficiary) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCollectFundsBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.account_balance_wallet, size: 18),
                label: const Text('Collect Funds'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildViewReceiptButton(),
        ],
      );
    } else if (widget.contract.status == 'terminated') {
      if (isRemitter) {
        return Column(
          children: [
            // Termination reason display for terminator
            if (widget.contract.terminationReason != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Termination Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.contract.terminationReason!,
                      style: TextStyle(
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.hourglass_empty, size: 18),
                label: const Text('Waiting for termination approval'),
              ),
            ),
          ],
        );
      } else if (isBeneficiary) {
        return Column(
          children: [
            // Termination reason display
            if (widget.contract.terminationReason != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termination Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.contract.terminationReason!,
                      style: TextStyle(
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onApproveTermination?.call(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text('Approve Termination'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onRequestWithdrawal?.call(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.money_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Request Withdrawal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.support_agent,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text('Contact Escrow Support'),
              ),
            ),
          ],
        );
      }
    } else if (widget.contract.status == 'closed') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Contract Terminated'),
            ),
          ),
          if (isRemitter) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Text(
                'Funds will be transferred back to your account in 30 minutes.',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ],
      );
    } else if (widget.contract.status == 'pendingpayout') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.hourglass_empty, size: 18),
              label: const Text('Processing Transfer'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Text(
              'Funds are being transferred to your account..',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          _buildViewReceiptButton(),
        ],
      );
    } else if (widget.contract.status == 'payedout') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Contract Closed Successfully'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Text(
              'Funds have been successfully transferred to your account.',
              style: TextStyle(color: Colors.green),
            ),
          ),
          const SizedBox(height: 8),
          _buildViewReceiptButton(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showCollectFundsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Transfer Funds to your account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred network and enter your phone number',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Payout method
              const Text(
                'Payout method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Funds will be sent to your mobile money',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Provider Selection
              const Text(
                'Mobile Provider',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _mobileProvider,
                items: (_providers.isNotEmpty
                        ? _providers.map((p) => MapEntry(p.name, p.name))
                        : _mobileProviders.entries)
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setModalState(() {
                    _mobileProvider = v!;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              const Text(
                'Phone number to receive funds',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (() {
                      try {
                        return _phoneFocusNode.hasFocus
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[300]!;
                      } catch (e) {
                        return Colors.grey[300]!;
                      }
                    })(),
                    width: (() {
                      try {
                        return _phoneFocusNode.hasFocus ? 2.0 : 1.0;
                      } catch (e) {
                        return 1.0;
                      }
                    })(),
                  ),
                  boxShadow: (() {
                    try {
                      return _phoneFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
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
                            ];
                    } catch (e) {
                      return [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ];
                    }
                  })(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(fontSize: 16),
                        onTap: () {
                          if (!mounted) return;
                          setModalState(() {});
                        },
                        onChanged: (value) {
                          if (!mounted) return;
                          setModalState(() {});
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
                        onPressed: () async {
                          final clipboardData =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (clipboardData?.text != null) {
                            _phoneController.text = clipboardData!.text!;
                            setModalState(() {});
                          }
                        },
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
              const SizedBox(height: 24),

              // Transfer Funds Button or Confirmation
              if (_showConfirmation)
                _buildTransferConfirmation(setModalState)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_phoneController.text.isNotEmpty)
                        ? () {
                            print('Transfer Funds button pressed');
                            print('Phone text: ${_phoneController.text}');
                            _showTransferConfirmation(context, setModalState);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Transfer Funds',
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
      ),
    );
  }

  void _showTransferConfirmation(
      BuildContext context, StateSetter setModalState) {
    setModalState(() {
      _showConfirmation = true;
    });
    if (mounted) {
      setState(() {
        _showConfirmation = true;
      });
    }
  }

  Widget _buildTransferConfirmation(StateSetter setModalState) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to transfer funds to this number?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _phoneController.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'By confirming, you agree to all terms and conditions. The company will not be responsible for any issues with the transfer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isTransferring
                ? null
                : () {
                    if (kDebugMode) {
                      print('Confirm & Continue button pressed');
                    }
                    _confirmTransfer(setModalState);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isTransferring
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(
                        radius: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Processing Transfer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text('Confirm & Continue'),
          ),
        ),
      ],
    );
  }

  static const Color _primaryColor = Color(0xFF2E7D32);

  Future<bool?> _showNameLookupConfirmation({
    required double amount,
    required String msisdn,
    required String provider,
    required String providerLabel,
    required String authToken,
  }) async {
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
        authToken: authToken,
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
        title: 'Confirm Payout',
      ),
    );
  }

  void _confirmTransfer(StateSetter setModalState) async {
    if (kDebugMode) {
      print('_confirmTransfer method called');
    }
    try {
      final contractService = ContractService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final String rawMsisdn = _phoneController.text.trim();
      final String msisdn = _formatPhoneNumber(rawMsisdn, _mobileProvider);
      final provider = _mobileProvider;
      final providerLabel = _mobileProviders[provider] ?? provider;
      final double amount = widget.contract.reward;

      final confirmed = await _showNameLookupConfirmation(
        amount: amount,
        msisdn: msisdn,
        provider: provider,
        providerLabel: providerLabel,
        authToken: userProvider.user!.id,
      );

      if (confirmed != true) return;

      setModalState(() {
        _isTransferring = true;
      });

      // Prepare request body
      final requestBody = {
        'contractId': widget.contract.id,
        'recipientNames': widget.contract.beneficiaryName ?? 'Unknown',
        'channel': 'mobile',
        'narration': 'Payout for completed job #${widget.contract.id}',
        'msisdn': msisdn,
        'provider': provider,
      };

      // Print request body for debugging
      print('=== PAYOUT API REQUEST ===');
      print('URL: ${AppConstants.baseUrl}/api/payouts/initiate');
      print('Headers:');
      print('  Content-Type: application/json');
      print('  Authorization: Bearer ${widget.contract.beneficiaryId}');
      print('Body:');
      print(jsonEncode(requestBody));
      print('========================');

      // Make API call to initiate payout
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/payouts/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.contract.beneficiaryId}',
        },
        body: jsonEncode(requestBody),
      );

      // Print response for debugging
      if (kDebugMode) {
        print('=== PAYOUT API RESPONSE ===');
      }
      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response Body: ${response.body}');
      }
      if (kDebugMode) {
        print('==========================');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update contract status to pendingpayout
        await contractService.updateContractStatus(
          widget.contract.id,
          'pendingpayout',
          currentUserName: userProvider.user?.fullName,
        );

        // Close the bottom sheet
        if (mounted) {
          Navigator.pop(context);
        }

        // Start monitoring contract status
        await _monitorContractStatus();
      } else {
        throw Exception('Failed to initiate payout: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setModalState(() {
          _isTransferring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating transfer: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _monitorContractStatus() async {
    const maxWaitTime = Duration(minutes: 5); // 5 minutes timeout
    const checkInterval = Duration(seconds: 3);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      try {
        final contractService = ContractService();
        final contract =
            await contractService.getContractDetails(widget.contract.id);

        if (contract?.status == 'payedout') {
          // Contract is now payedout, show success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funds have been successfully transferred!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        }
      } catch (e) {
        // Continue monitoring even if there's an error fetching contract
      }

      await Future.delayed(checkInterval);
    }

    // Timeout reached
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Transfer is taking longer than expected. Please check back later.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String? _extractLookupName(dynamic lookupResult) {
    if (lookupResult == null) return null;
    if (lookupResult is Map) {
      return lookupResult['name']?.toString() ??
          lookupResult['accountName']?.toString() ??
          lookupResult['fullName']?.toString();
    }
    return null;
  }

  void _openWhatsApp() async {
    const phoneNumber = '+255620719589';
    const message = 'Hello, I need assistance with a contract termination.';
    final encodedMessage = Uri.encodeComponent(message);

    final url = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Primary method failed, trying fallback...");

      final fallbackUrl =
          Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage');

      if (!await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication)) {
        debugPrint("Both methods failed");
      }
    }
  }

  Widget _buildViewReceiptButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ContractSummaryBottomSheet.showReceipt(
          context: context,
          contract: widget.contract,
        ),
        icon: const Icon(Icons.receipt_long, size: 18),
        label: const Text('View Receipt'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green[800],
          side: BorderSide(color: Colors.green[300]!),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
