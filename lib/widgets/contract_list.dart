import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';

class ContractList extends StatelessWidget {
  final String userId;
  final ContractService contractService;

  const ContractList({
    super.key,
    required this.userId,
    required this.contractService,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 CONTRACT LIST: Building contract list for user: $userId');

    return StreamBuilder<List<ContractModel>>(
      stream: contractService.getAuthenticatedUserContracts(userId),
      builder: (context, snapshot) {
        print(
            '🔍 CONTRACT LIST: StreamBuilder snapshot state: ${snapshot.connectionState}');
        print('🔍 CONTRACT LIST: Has data: ${snapshot.hasData}');
        print('🔍 CONTRACT LIST: Has error: ${snapshot.hasError}');

        if (snapshot.hasError) {
          print('❌ CONTRACT LIST ERROR: ${snapshot.error}');
          print('❌ CONTRACT LIST ERROR DETAILS: ${snapshot.error.toString()}');
          return Center(
            child: Text(
              'Error loading contracts: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final contracts = snapshot.data!;
        print('🔍 CONTRACT LIST: Loaded ${contracts.length} contracts');

        if (contracts.isEmpty) {
          print('🔍 CONTRACT LIST: No contracts found, showing empty state');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Contracts Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first contract to get started',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create contract screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Contract'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                title: Text(
                  contract.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(contract.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(contract.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contract.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reward: \$${contract.reward.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to contract details
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'non-active':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
