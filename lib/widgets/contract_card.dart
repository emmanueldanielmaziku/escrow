import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../utils/constants.dart';
import 'glassmorphism_card.dart';
import 'status_badge.dart';

class ContractCard extends StatelessWidget {
  final ContractModel contract;
  final bool isCreator;
  final VoidCallback onTap;
  final VoidCallback? onFundPressed;
  final VoidCallback? onWithdrawPressed;
  final VoidCallback? onConfirmPressed;
  final VoidCallback? onDeclinePressed;

  const ContractCard({
    super.key,
    required this.contract,
    required this.isCreator,
    required this.onTap,
    this.onFundPressed,
    this.onWithdrawPressed,
    this.onConfirmPressed,
    this.onDeclinePressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    final dateFormat = DateFormat("MMM d, yyyy");
    
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphismCard(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contract.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: contract.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contract.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TSh ${currencyFormat.format(contract.amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Created: ${dateFormat.format(contract.createdAt.toDate())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (_shouldShowButtons())
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildActionButtons(),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowButtons() {
    if (isCreator && contract.status == AppConstants.notFunded) {
      return true; // Show Fund button for creator when not funded
    } else if (!isCreator && contract.status == AppConstants.active && !contract.withdrawalRequested) {
      return true; // Show Withdraw button for invitee when active
    } else if (isCreator && contract.status == AppConstants.active && contract.withdrawalRequested) {
      return true; // Show Confirm/Decline buttons for creator when withdrawal requested
    }
    return false;
  }

  Widget _buildActionButtons() {
    if (isCreator && contract.status == AppConstants.notFunded) {
      return ElevatedButton(
        onPressed: onFundPressed,
        child: const Text('Fund Contract'),
      );
    } else if (!isCreator && contract.status == AppConstants.active && !contract.withdrawalRequested) {
      return ElevatedButton(
        onPressed: onWithdrawPressed,
        child: const Text('Request Withdrawal'),
      );
    } else if (isCreator && contract.status == AppConstants.active && contract.withdrawalRequested) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirmPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onDeclinePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Decline'),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
