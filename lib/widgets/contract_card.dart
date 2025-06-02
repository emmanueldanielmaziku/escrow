import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ContractCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'TSh ',
      decimalDigits: 0,
      locale: 'en_US',
    );

    final isBenefactor = contract.benefactorId == userProvider.user?.id;
    final isBeneficiary = contract.beneficiaryId == userProvider.user?.id;
    
  

    return Container(
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
                    color: ContractModel.getStatusColor(contract.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ContractModel.getStatusColor(contract.status), width: 0.5),
                  ),
                  child: Text(
                    ContractModel.getStatusText(contract.status),
                    style: TextStyle(
                      color: ContractModel.getStatusColor(contract.status),
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
                    border: Border.all(color: theme.colorScheme.primary, width: 0.5),
                  ),
                  child: Text(
                    currencyFormat.format(contract.reward),
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
              contract.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              contract.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Created Date
            Text(
              'Created ${DateFormat('MMM d, y').format(contract.createdAt)}',
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
                  // Benefactor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Benefactor',
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
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    "https://avatar.iran.liara.run/public",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contract.benefactorName ?? 'Not assigned',
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
                                  shape: BoxShape.circle,
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      "https://avatar.iran.liara.run/public",
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  contract.beneficiaryName ?? 'Not assigned',
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
            // Action Buttons
            if (contract.status == 'non-active') ...[
              const SizedBox(height: 16),
              if (isBenefactor && contract.role == 'Benefactor')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDeleteContract,
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
                )
                else if (isBeneficiary && contract.role == 'Beneficiary')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDeleteContract,
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
                )
              else if (isBeneficiary && contract.role == 'Benefactor')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAcceptInvitation,
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
                )
                     else if (isBenefactor && contract.role == 'Beneficiary')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAcceptInvitation,
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
                ),
            ] else if (contract.status == 'unfunded') ...[
              const SizedBox(height: 16),
              if (isBenefactor && contract.role == 'Beneficiary')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onFundContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18),
                    label: const Text('Fund Contract'),
                  ),
                )
                     else if (isBenefactor && contract.role == 'Benefactor')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onFundContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18),
                    label: const Text('Fund Contract'),
                  ),
                )
              else if (isBeneficiary && contract.role == 'Benefactor')
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
                    label: const Text('Wait for contract to be funded'),
                  ),
                )
                  else if (isBeneficiary && contract.role == 'Beneficiary')
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
                    label: const Text('Wait for contract to be funded'),
                  ),
                ),
            ] else if (contract.status == 'active') ...[
              const SizedBox(height: 16),
              if (isBenefactor)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onTerminateContract?.call(),
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
                )
              else if (isBeneficiary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onRequestWithdrawal?.call(),
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
            ] else if (contract.status == 'withdraw') ...[
              const SizedBox(height: 16),
              if (isBenefactor)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onConfirmWithdrawal?.call(),
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
                        onPressed: () => onDeclineWithdrawal?.call(),
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
                )
              else if (isBeneficiary)
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
                    label: const Text('Waiting for approval'),
                  ),
                ),
            ] else if (contract.status == 'completed') ...[
              const SizedBox(height: 16),
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
            ] else if (contract.status == 'terminated') ...[
              const SizedBox(height: 16),
              if (isBenefactor)
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
                )
              else if (isBeneficiary)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onApproveTermination?.call(),
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
                        onPressed: () => onRequestWithdrawal?.call(),
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
                ),
            ] else if (contract.status == 'closed') ...[
              const SizedBox(height: 16),
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
              if (isBenefactor) ...[
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
          ],
        ),
      ),
    );
  }
}
