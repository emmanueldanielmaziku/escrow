// ignore_for_file: deprecated_member_use

import 'package:escrow_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/contract_service.dart';
import '../widgets/contract_card.dart';
import '../models/contract_model.dart';
import '../screens/create_contract_screen.dart';
import '../screens/fund_contract_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sortOrder = 'latest';
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isScrolledNotifier = ValueNotifier<bool>(false);
  final _contractService = ContractService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isScrolledNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolledNotifier.value) {
      _isScrolledNotifier.value = true;
    } else if (_scrollController.offset <= 0 && _isScrolledNotifier.value) {
      _isScrolledNotifier.value = false;
    }
  }

  void _showCreateContractSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateContractScreen(),
      ),
    );
  }

  Future<void> _handleDeleteContract(ContractModel contract) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Contract'),
          content: const Text(
            'Are you sure you want to delete this contract? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleting contract...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Delete the contract
        await _contractService.deleteContract(contract.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting contract: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateContractSheet,
        backgroundColor: Colors.green,
        elevation: 4,
        child: const Icon(
          Iconsax.add_circle,
          color: Colors.white,
          size: 24,
        ),
      ),
      body: Column(
        children: [
          // Fixed Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3),
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              image: const DecorationImage(
                                image: NetworkImage(
                                  "https://avatar.iran.liara.run/public",
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome,',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16.0,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              userProvider.user?.fullName ?? 'User',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                    IconButton.outlined(
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 151, 209, 161),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      onPressed: () async {
                        try {
                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );

                          // Clear user data from provider
                          userProvider.clearUser();

                          // Sign out from auth service
                          await authService.signOut();

                          if (context.mounted) {
                            // Navigate to login screen
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error signing out: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Iconsax.logout,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Total Contracts Card
                StreamBuilder<List<ContractModel>>(
                  stream: _contractService.getAuthenticatedUserContracts(
                    userProvider.user?.id ?? '',
                  ),
                  builder: (context, snapshot) {
                    final totalContracts = snapshot.data?.length ?? 0;
                    return Container(
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
                            color: Colors.black.withOpacity(0.1),
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
                                  color:
                                      const Color.fromARGB(198, 100, 202, 103),
                                  width: 0.5),
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Iconsax.document_text,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            totalContracts.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Contracts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Iconsax.sort,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            onSelected: (String value) {
                              setState(() {
                                _sortOrder = value;
                              });
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'latest',
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.arrow_down_1,
                                      size: 18,
                                      color: _sortOrder == 'latest'
                                          ? theme.colorScheme.primary
                                          : null,
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
                                      Iconsax.arrow_up_1,
                                      size: 18,
                                      color: _sortOrder == 'oldest'
                                          ? theme.colorScheme.primary
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Oldest First'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Scrollable Contracts List Section
          Expanded(
            child: StreamBuilder<List<ContractModel>>(
              stream: _contractService.getAuthenticatedUserContracts(
                userProvider.user?.id ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final contracts = snapshot.data ?? [];

                // Sort contracts based on _sortOrder
                contracts.sort((a, b) {
                  if (_sortOrder == 'latest') {
                    return b.createdAt.compareTo(a.createdAt);
                  } else {
                    return a.createdAt.compareTo(b.createdAt);
                  }
                });

                if (contracts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contracts yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first contract by \ntapping the button below',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    return ContractCard(
                      contract: contract,
                      onFundContract: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FundContractScreen(
                              contract: contract,
                            ),
                          ),
                        );
                      },
                      onRequestWithdrawal: () async {
                        try {
                          await _contractService.requestWithdrawal(contract.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Withdrawal requested successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error requesting withdrawal: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onDeleteContract: () => _handleDeleteContract(contract),
                      onAcceptInvitation: () async {
                        try {
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          final user = userProvider.user;

                          if (user == null) {
                            throw Exception('User not found');
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Accepting invitation...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }

                          await _contractService.acceptContract(
                            contractId: contract.id,
                            userId: user.id,
                            userFullName: user.fullName,
                            userPhone: user.phone,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contract accepted successfully'),
                                backgroundColor: Colors.green,
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
                      onTerminateContract: () async {
                        try {
                          await _contractService.terminateContract(contract.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Contract terminated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error terminating contract: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onConfirmWithdrawal: () async {
                        try {
                          await _contractService.confirmWithdrawal(contract.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Withdrawal confirmed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error confirming withdrawal: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onDeclineWithdrawal: () async {
                        try {
                          await _contractService.declineWithdrawal(contract.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Withdrawal request declined'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error declining withdrawal: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onApproveTermination: () async {
                        try {
                          await _contractService
                              .approveTermination(contract.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Termination approved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error approving termination: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
