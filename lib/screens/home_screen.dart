// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/create_contract_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sortOrder = 'latest';
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  void _showCreateContractSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateContractSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isScrolled ? 56 : 180,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _showCreateContractSheet,
          backgroundColor: theme.colorScheme.primary,
          icon: const Icon(Iconsax.add_circle, color: Colors.white),
          label: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isScrolled ? 0.0 : 1.0,
            child: const Text(
              'New Contract',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // User Info Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(255, 61, 114, 60),
                    theme.colorScheme.primary.withOpacity(1.0),
                    theme.colorScheme.primary.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome,',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userProvider.user?.fullName ?? 'User',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                image: const DecorationImage(
                                    image: NetworkImage(
                                        "https://avatar.iran.liara.run/public"))),

                            // child: Center(
                            //   child: Text(
                            //     (userProvider.user?.fullName ?? 'U')[0]
                            //         .toUpperCase(),
                            //     style: const TextStyle(
                            //       color: Colors.white,
                            //       fontSize: 18,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            style: IconButton.styleFrom(
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 151, 209, 161)),
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                            onPressed: () async {
                              try {
                                final authService = Provider.of<AuthService>(
                                    context,
                                    listen: false);
                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);

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
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Total Contracts Card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('contracts')
                        .where('userId', isEqualTo: userProvider.user?.id)
                        .orderBy('createdAt',
                            descending: _sortOrder == 'latest')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final totalContracts = snapshot.data?.docs.length ?? 0;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
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
                            Text(
                              ' Contracts',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
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
          ],
        ),
      ),
    );
  }
}



// Based on the contract model lets create a Contrcact Card , theat will have a :
// 1. Title with a contract icon on its left.. 
// 2. Below will have contract Description ,
// 3. Time last modified and Time last created 
// 4. Status
// 5 Action button (Action buttons will be visible based on the status) where as we will have the following set of action buttons 
//      1. Fund Contract (This will be visible to the Benefactor )

