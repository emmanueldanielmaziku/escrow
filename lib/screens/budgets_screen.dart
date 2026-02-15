import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:random_avatar/random_avatar.dart';
import 'dart:async';
import '../providers/user_provider.dart';
import '../models/budget_contract_model.dart';
import 'create_budget_contract_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  // Filter states
  String _sortOrder = 'latest';
  ContractType? _filterContractType;
  BudgetContractStatus? _filterStatus;

  // Dummy data for budgets
  List<BudgetContractModel> _allBudgetContracts = [
    BudgetContractModel(
      id: '1',
      title: 'Website Development',
      description: 'Complete website redesign project',
      amount: 500000,
      fundedAmount: 250000,
      contractType: ContractType.nonNegotiable,
      status: BudgetContractStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      contractEndDate: DateTime.now().add(const Duration(days: 25)),
      contractTerm: const Duration(days: 30),
      remitterName: 'John Doe',
      beneficiaryName: 'Jane Smith',
    ),
    BudgetContractModel(
      id: '2',
      title: 'Mobile App Design',
      description: 'UI/UX design for mobile application',
      amount: 300000,
      fundedAmount: 0,
      contractType: ContractType.negotiable,
      status: BudgetContractStatus.unfunded,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      remitterName: 'Alice Johnson',
      beneficiaryName: 'Bob Williams',
    ),
    BudgetContractModel(
      id: '3',
      title: 'Content Writing',
      description: 'Blog posts and articles writing',
      amount: 200000,
      fundedAmount: 200000,
      contractType: ContractType.negotiable,
      status: BudgetContractStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      remitterName: 'Mike Brown',
      beneficiaryName: 'Sarah Davis',
    ),
    BudgetContractModel(
      id: '4',
      title: 'Logo Design',
      description: 'Brand identity and logo design',
      amount: 150000,
      fundedAmount: 150000,
      contractType: ContractType.nonNegotiable,
      status: BudgetContractStatus.sahara,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      contractEndDate: DateTime.now().subtract(const Duration(days: 5)),
      contractTerm: const Duration(days: 15),
      remitterName: 'David Wilson',
      beneficiaryName: 'Emma Taylor',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Update timer every second for countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  List<BudgetContractModel> get _filteredContracts {
    var filtered = List<BudgetContractModel>.from(_allBudgetContracts);

    // Filter by contract type
    if (_filterContractType != null) {
      filtered =
          filtered.where((c) => c.contractType == _filterContractType).toList();
    }

    // Filter by status
    if (_filterStatus != null) {
      filtered = filtered.where((c) => c.status == _filterStatus).toList();
    }

    // Sort contracts
    filtered.sort((a, b) {
      if (_sortOrder == 'latest') {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return filtered;
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _showAddFundsDialog(BudgetContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text('Current: TSh ${contract.fundedAmount.toStringAsFixed(2)}'),
            Text('Target: TSh ${contract.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement add funds functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funds added successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BudgetContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text(
              'Available: TSh ${contract.fundedAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement withdraw functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funds withdrawn successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showCloseContractDialog(BudgetContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Contract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text(
              'This will permanently close the contract.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (contract.fundedAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Available funds: TSh ${contract.fundedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Funds will be returned to your account.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement close contract functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contract closed successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Contract'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final userAvatar = RandomAvatar(
      user?.id ?? 'default',
      height: 42,
      width: 42,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Fixed Header Section (matching HomeScreen style)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 55, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green, Colors.green, Colors.green],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: userAvatar,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mai sahara',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 14.0,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'Budgeting feature',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateBudgetContractScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Iconsax.add_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Filter Card (matching HomeScreen style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(198, 100, 202, 103),
                            width: 0.5,
                          ),
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.wallet_3,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _filteredContracts.length.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Budget Contracts',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Iconsax.setting_3,
                          color: Colors.green,
                          size: 22,
                        ),
                        onSelected: (String value) {
                          setState(() {
                            if (value == 'latest' || value == 'oldest') {
                              _sortOrder = value;
                            } else if (value == 'all_types') {
                              _filterContractType = null;
                            } else if (value == 'negotiable') {
                              _filterContractType = ContractType.negotiable;
                            } else if (value == 'non_negotiable') {
                              _filterContractType = ContractType.nonNegotiable;
                            } else if (value == 'all_status') {
                              _filterStatus = null;
                            } else if (value == 'active') {
                              _filterStatus = BudgetContractStatus.active;
                            } else if (value == 'sahara') {
                              _filterStatus = BudgetContractStatus.sahara;
                            } else if (value == 'unfunded') {
                              _filterStatus = BudgetContractStatus.unfunded;
                            } else if (value == 'clear_all') {
                              _filterContractType = null;
                              _filterStatus = null;
                              _sortOrder = 'latest';
                            }
                          });
                        },
                        itemBuilder: (BuildContext context) => [
                          // Sort Options
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Sort By',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'latest',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.trend_up,
                                  size: 18,
                                  color: _sortOrder == 'latest'
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Latest First'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'oldest',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.trend_down,
                                  size: 18,
                                  color: _sortOrder == 'oldest'
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Oldest First'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          // Contract Type Filter
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Contract Type',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'all_types',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.document,
                                  size: 18,
                                  color: _filterContractType == null
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('All Types'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'negotiable',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.lock_1,
                                  size: 18,
                                  color: _filterContractType ==
                                          ContractType.negotiable
                                      ? Colors.orange
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Negotiable'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'non_negotiable',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.lock,
                                  size: 18,
                                  color: _filterContractType ==
                                          ContractType.nonNegotiable
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Non-Negotiable'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          // Status Filter
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'all_status',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.filter,
                                  size: 18,
                                  color: _filterStatus == null
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('All Status'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  size: 18,
                                  color: _filterStatus ==
                                          BudgetContractStatus.active
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Active'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'sahara',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.wallet_3,
                                  size: 18,
                                  color: _filterStatus ==
                                          BudgetContractStatus.sahara
                                      ? Colors.blue
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Sahara'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'unfunded',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.wallet_1,
                                  size: 18,
                                  color: _filterStatus ==
                                          BudgetContractStatus.unfunded
                                      ? Colors.orange
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                const Text('Unfunded'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          // Clear Filters
                          PopupMenuItem<String>(
                            value: 'clear_all',
                            child: const Row(
                              children: [
                                Icon(
                                  Iconsax.refresh,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Clear All Filters',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _filteredContracts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredContracts.length,
                    itemBuilder: (context, index) {
                      return _buildBudgetContractCard(
                          _filteredContracts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.wallet_3,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Budget Contracts Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first budget contract to start managing your funds',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBudgetContractScreen(),
                  ),
                );
              },
              icon: const Icon(Iconsax.add),
              label: const Text(
                'Create Budget Contract',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetContractCard(BudgetContractModel contract) {
    final statusColor = BudgetContractModel.getStatusColor(contract.status);
    final statusText = BudgetContractModel.getStatusText(contract.status);
    final contractTypeText =
        BudgetContractModel.getContractTypeText(contract.contractType);
    final progress =
        contract.amount > 0 ? contract.fundedAmount / contract.amount : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  contract.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Contract Type & Term
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                // Contract Type
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        contract.contractType == ContractType.negotiable
                            ? Iconsax.lock_1
                            : Iconsax.lock,
                        size: 16,
                        color: contract.contractType == ContractType.negotiable
                            ? Colors.orange
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contractTypeText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              contract.contractType == ContractType.negotiable
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contract Term Timer
                if (contract.contractEndDate != null &&
                    contract.remainingTime != null)
                  Row(
                    children: [
                      const Icon(
                        Iconsax.timer,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(contract.remainingTime!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Funding Progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Funding Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TSh ${contract.fundedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'TSh ${contract.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // For Negotiable contracts: Can withdraw and close anytime
                if (contract.contractType == ContractType.negotiable &&
                    contract.status == BudgetContractStatus.active) ...[
                  // Withdraw button (if has funds)
                  if (contract.fundedAmount > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showWithdrawDialog(contract),
                        icon: const Icon(Iconsax.arrow_down_2, size: 18),
                        label: const Text('Withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  // Add Funds button (if not fully funded)
                  if (!contract.isFullyFunded) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddFundsDialog(contract),
                        icon: const Icon(Iconsax.add, size: 18),
                        label: const Text('Add Funds'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // Close/Remove button next to Add Funds for negotiable
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showCloseContractDialog(contract),
                      icon: const Icon(Iconsax.close_circle),
                      color: Colors.red,
                      tooltip: 'Close Contract',
                    ),
                  ],
                  // Close button (if fully funded, no Add Funds button)
                  if (contract.isFullyFunded) const SizedBox(width: 8),
                  if (contract.isFullyFunded)
                    IconButton(
                      onPressed: () => _showCloseContractDialog(contract),
                      icon: const Icon(Iconsax.close_circle),
                      color: Colors.red,
                      tooltip: 'Close Contract',
                    ),
                ]
                // For Non-Negotiable contracts: Standard behavior
                else ...[
                  if (!contract.isFullyFunded) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddFundsDialog(contract),
                        icon: const Icon(Iconsax.add, size: 18),
                        label: const Text('Add Funds'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // Close/Remove button for unfunded contracts
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showCloseContractDialog(contract),
                      icon: const Icon(Iconsax.close_circle),
                      color: Colors.red,
                      tooltip: 'Remove Contract',
                    ),
                  ],
                  if (contract.isFullyFunded)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showWithdrawDialog(contract),
                        icon: const Icon(Iconsax.arrow_down_2, size: 18),
                        label: const Text('Withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
