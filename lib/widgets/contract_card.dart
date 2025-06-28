import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';
import '../models/contract_model.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ContractCard extends StatefulWidget {
  final ContractModel contract;
  final VoidCallback? onFundContract;
  final VoidCallback? onRequestWithdrawal;
  final VoidCallback? onDeleteContract;
  final VoidCallback? onAcceptInvitation;
  final VoidCallback? onTerminateContract;
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
              color: Colors.black.withOpacity(0.03),
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
              // Status and Price Row
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
              // Description with expandable functionality
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
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Contract'),
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
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
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
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
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
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => widget.onTerminateContract?.call(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Terminate Contract'),
          ),
        );
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
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm Withdrawal'),
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
                icon: const Icon(Icons.cancel_outlined, size: 18),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Text(
                'Contract closed successfully. Funds will be transferred to your account in 30 minutes.',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ],
      );
    } else if (widget.contract.status == 'terminated') {
      if (isRemitter) {
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
            label: const Text('Waiting for termination approval'),
          ),
        );
      } else if (isBeneficiary) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onApproveTermination?.call(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve Termination'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onRequestWithdrawal?.call(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.money_outlined, size: 18),
                label: const Text('Request Withdrawal'),
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
    }

    return const SizedBox.shrink();
  }
}
