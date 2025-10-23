// ignore_for_file: use_build_context_synchronously

import 'package:escrow_app/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contract_model.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/contract_service.dart';

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
  String? _selectedNetwork;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _showConfirmation = false;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _terminationReasonController.addListener(_onTerminationReasonChanged);
  }

  @override
  void dispose() {
    _terminationReasonController.removeListener(_onTerminationReasonChanged);
    _terminationReasonController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
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
          border: Border.all(width: 0.5, color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
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
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      overflow:
                          _isDescriptionExpanded ? null : TextOverflow.ellipsis,
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
          return SizedBox(
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
          );
        }
      } else if (isBeneficiary) {
        return SizedBox(
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
              const Text(
                'Choose your preferred network and enter your phone number',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Network Selection
              const Text(
                'Select payment channel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkOption(
                      'Mix by Yas',
                      'assets/icons/mixx.png',
                      'mix',
                      setModalState,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNetworkOption(
                      'Airtel Money',
                      'assets/icons/airtel.png',
                      'airtel',
                      setModalState,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              const Text(
                'Phone number to recieve funds',
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
                    onPressed: _selectedNetwork != null &&
                            _phoneController.text.isNotEmpty
                        ? () {
                            print('Transfer Funds button pressed');
                            print('Selected network: $_selectedNetwork');
                            print('Phone text: ${_phoneController.text}');
                            _showTransferConfirmation(context, setModalState);
                          }
                        : () {
                            print('Transfer Funds button disabled');
                            print('Selected network: $_selectedNetwork');
                            print('Phone text: ${_phoneController.text}');
                          },
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

  Widget _buildNetworkOption(
    String name,
    String iconPath,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedNetwork == value;
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedNetwork = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  iconPath,
                  scale: iconPath == "assets/icons/mixx.png" ? 12.0 : 23.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.green : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferConfirmation(
      BuildContext context, StateSetter setModalState) {
    setModalState(() {
      _showConfirmation = true;
    });
    setState(() {
      _showConfirmation = true;
    });
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
                '${_phoneController.text} (${_selectedNetwork == 'mix' ? 'Mix by Yas' : 'Airtel Money'})',
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

  void _confirmTransfer(StateSetter setModalState) async {
    if (kDebugMode) {
      print('_confirmTransfer method called');
    }
    try {
      if (kDebugMode) {
        print('Setting _isTransferring to true');
      }
      setModalState(() {
        _isTransferring = true;
      });

      final contractService = ContractService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Format phone number to international format
      String formattedMsisdn = _phoneController.text.trim();
      if (!formattedMsisdn.startsWith('255')) {
        if (formattedMsisdn.startsWith('0')) {
          formattedMsisdn = '255${formattedMsisdn.substring(1)}';
        } else {
          formattedMsisdn = '255$formattedMsisdn';
        }
      }

      // Determine channel based on selected network
      String channel =
          _selectedNetwork == 'mix' ? 'TZ-TIGO-B2C' : 'TZ-AIRTEL-B2C';

      // Prepare request body
      final requestBody = {
        'contractId': widget.contract.id,
        'recipientNames': widget.contract.beneficiaryName ?? 'Unknown',
        'msisdn': formattedMsisdn,
        'channel': channel,
        'narration': 'Payout for completed job #${widget.contract.id}',
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
}
