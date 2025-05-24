import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/contract_model.dart';
import '../../services/contract_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/status_badge.dart';
import '../contracts/contract_details_screen.dart';

class InvitationsTab extends StatelessWidget {
  const InvitationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final contractService = ContractService();
    final currentUserId = authService.getCurrentUserId();

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view invitations'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<ContractModel>>(
        stream: contractService.getUserInvitations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final invitations = snapshot.data!;

          if (invitations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: invitations.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return _buildInvitationCard(context, invitation);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Invitations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any pending contract invitations. When someone invites you to a contract, it will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, ContractModel invitation) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  invitation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: invitation.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            invitation.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'Amount: TSh ${invitation.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onDeclinePressed(context, invitation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onAcceptPressed(context, invitation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAcceptPressed(
      BuildContext context, ContractModel invitation) async {
    final contractService = ContractService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Contract'),
        content: const Text(
          'Are you sure you want to accept this contract? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await contractService.acceptContract(invitation.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppConstants.contractAcceptedMsg),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContractDetailsScreen(
                        contract: invitation.copyWith(
                          status: AppConstants.notFunded,
                          acceptedAt: Timestamp.now(),
                        ),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accepting contract: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeclinePressed(
      BuildContext context, ContractModel invitation) async {
    final contractService = ContractService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Contract'),
        content: const Text(
          'Are you sure you want to decline this contract? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await contractService.declineContract(invitation.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppConstants.contractDeclinedMsg),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error declining contract: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
