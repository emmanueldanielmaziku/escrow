// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:escrow_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:random_avatar/random_avatar.dart';
import '../providers/user_provider.dart';
import '../services/contract_service.dart';
import '../widgets/contract_card.dart';
import '../models/contract_model.dart';
import '../screens/create_contract_screen.dart';
import '../screens/fund_contract_screen.dart';
import '../utils/custom_snackbar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

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
          CustomSnackBar.show(
            context: context,
            message: 'Deleting contract...',
            type: SnackBarType.info,
            duration: const Duration(seconds: 1),
          );
        }

        // Delete the contract
        await _contractService.deleteContract(contract.id);

        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Contract deleted successfully',
            type: SnackBarType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error deleting contract: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleRequestWithdrawal(ContractModel contract) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      await _contractService.requestWithdrawal(
        contract.id,
        currentUserName: user?.fullName,
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Withdrawal requested successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error requesting withdrawal: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleTerminateContract(ContractModel contract,
      {String? terminationReason}) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      await _contractService.terminateContract(
        contract.id,
        terminationReason: terminationReason,
        currentUserName: user?.fullName,
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Contract terminated successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error terminating contract: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleConfirmWithdrawal(ContractModel contract) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      await _contractService.confirmWithdrawal(
        contract.id,
        currentUserName: user?.fullName,
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Withdrawal confirmed successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error confirming withdrawal: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleDeclineWithdrawal(ContractModel contract) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      await _contractService.declineWithdrawal(
        contract.id,
        currentUserName: user?.fullName,
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Withdrawal declined successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error declining withdrawal: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleApproveTermination(ContractModel contract) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      await _contractService.approveTermination(
        contract.id,
        currentUserName: user?.fullName,
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Contract termination approved successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error approving termination: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    Widget userAvatar = RandomAvatar(userProvider.user?.fullName ?? 'User',
        trBackground: true, height: 50, width: 50);
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showCreateContractSheet,
      //   backgroundColor: Colors.green,
      //   elevation: 4,
      //   child: const Icon(
      //     Iconsax.add_circle,
      //     color: Colors.white,
      //     size: 24,
      //   ),
      // ),
      body: Column(
        children: [
          // Fixed Header Section
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
                        GestureDetector(
                          onTap: () {
                            if (widget.onProfileTap != null) {
                              widget.onProfileTap!();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileScreen()),
                              );
                            }
                          },
                          child: Container(
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
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Contracts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14.0,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'Mai Escrow',
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
                    IconButton(
                      onPressed: _showCreateContractSheet

                      // try {
                      //   final authService = Provider.of<AuthService>(
                      //     context,
                      //     listen: false,
                      //   );
                      //   final userProvider = Provider.of<UserProvider>(
                      //     context,
                      //     listen: false,
                      //   );

                      //   // Clear user data from provider
                      //   userProvider.clearUser();

                      //   // Sign out from auth service
                      //   await authService.signOut();

                      //   if (context.mounted) {
                      //     // Navigate to login screen
                      //     Navigator.of(context).pushNamedAndRemoveUntil(
                      //       '/',
                      //       (route) => false,
                      //     );
                      //   }
                      // } catch (e) {
                      //   if (context.mounted) {
                      //     CustomSnackBar.show(
                      //       context: context,
                      //       message: 'Error signing out: $e',
                      //       type: SnackBarType.error,
                      //     );
                      //   }
                      // }

                      ,
                      icon: const Icon(
                        Iconsax.add_circle,
                        color: Colors.white,
                        size: 28,
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
                              Iconsax.setting_3,
                              color: theme.colorScheme.primary,
                              size: 22,
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
                                      Iconsax.trend_up,
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
                                      Iconsax.trend_down,
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
                      onDeleteContract: () => _handleDeleteContract(contract),
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
                        await _handleRequestWithdrawal(contract);
                      },
                      onAcceptInvitation: () async {
                        try {
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          final user = userProvider.user;

                          if (user == null) {
                            throw Exception('User not found');
                          }

                          if (context.mounted) {
                            CustomSnackBar.show(
                              context: context,
                              message: 'Accepting invitation...',
                              type: SnackBarType.info,
                              duration: const Duration(seconds: 1),
                            );
                          }

                          await _contractService.acceptContract(
                            contractId: contract.id,
                            userId: user.id,
                            userFullName: user.fullName,
                            userPhone: user.phone,
                          );

                          if (context.mounted) {
                            CustomSnackBar.show(
                              context: context,
                              message: 'Contract accepted successfully',
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context: context,
                              message: 'Error accepting contract: $e',
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                      onTerminateContract: (String terminationReason) async {
                        await _handleTerminateContract(contract,
                            terminationReason: terminationReason);
                      },
                      onConfirmWithdrawal: () async {
                        await _handleConfirmWithdrawal(contract);
                      },
                      onDeclineWithdrawal: () async {
                        await _handleDeclineWithdrawal(contract);
                      },
                      onApproveTermination: () async {
                        await _handleApproveTermination(contract);
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
