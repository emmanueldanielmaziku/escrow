import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../utils/constants.dart';
import '../../widgets/contract_card.dart';
import '../contracts/contract_details_screen.dart';
import '../contracts/create_contract_screen.dart';

class ContractsTab extends StatefulWidget {
  const ContractsTab({super.key});

  @override
  State<ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<ContractsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Simulated contract data for demonstration
  List<ContractModel> contracts = [];
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // TODO: Load contracts and set currentUserId as needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter contracts by status
    final activeContracts = contracts
        .where((contract) =>
            contract.status != AppConstants.closed &&
            contract.status != AppConstants.terminated &&
            contract.status != AppConstants.declined)
        .toList();
    final completedContracts = contracts
        .where((contract) => contract.status == AppConstants.closed)
        .toList();
    final terminatedContracts = contracts
        .where((contract) =>
            contract.status == AppConstants.terminated ||
            contract.status == AppConstants.declined)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Terminated'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContractsList(
            context,
            activeContracts,
            currentUserId,
            'No active contracts',
            'You don\'t have any active contracts yet. Create a new contract to get started.',
          ),
          _buildContractsList(
            context,
            completedContracts,
            currentUserId,
            'No completed contracts',
            'You don\'t have any completed contracts yet.',
          ),
          _buildContractsList(
            context,
            terminatedContracts,
            currentUserId,
            'No terminated contracts',
            'You don\'t have any terminated contracts.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateContractScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContractsList(
    BuildContext context,
    List<ContractModel> contracts,
    String currentUserId,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (contracts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: const TextStyle(
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
    return ListView.builder(
      itemCount: contracts.length,
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final isCreator = contract.creatorId == currentUserId;
        return ContractCard(
          contract: contract,
          isCreator: isCreator,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContractDetailsScreen(contract: contract),
              ),
            );
          },
          onFundPressed: isCreator && contract.status == AppConstants.notFunded
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContractDetailsScreen(
                          contract: contract, initialTabIndex: 1),
                    ),
                  );
                }
              : null,
          onWithdrawPressed: !isCreator &&
                  contract.status == AppConstants.active &&
                  !contract.withdrawalRequested
              ? () {
                  // TODO: Implement withdrawal logic
                }
              : null,
          onConfirmPressed: isCreator &&
                  contract.status == AppConstants.active &&
                  contract.withdrawalRequested
              ? () {
                  // TODO: Implement confirm withdrawal logic
                }
              : null,
          onDeclinePressed: isCreator &&
                  contract.status == AppConstants.active &&
                  contract.withdrawalRequested
              ? () {
                  // TODO: Implement decline withdrawal logic
                }
              : null,
        );
      },
    );
  }
}
