// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/contract_service.dart';
import '../services/contacts_cache_service.dart';
import '../models/user_model.dart';
import '../utils/custom_snackbar.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'Remitter';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _secondParticipantController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingContacts = false;
  final _contractService = ContractService();
  final _contactsCacheService = ContactsCacheService();
  UserModel? _selectedSecondParticipant;
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Load contacts in background when screen initializes
    _loadCachedContacts();
    _contactsCacheService.loadContactsInBackground();
  }

  // Load contacts from cache immediately
  void _loadCachedContacts() {
    if (_contactsCacheService.hasCachedContacts) {
      setState(() {
        _allContacts = _contactsCacheService.cachedContacts!;
        _filteredContacts = _allContacts;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _secondParticipantController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _loadContacts({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      // Use cache service to load contacts
      await _contactsCacheService.loadContacts(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _allContacts = _contactsCacheService.cachedContacts ?? [];
          _filteredContacts = _allContacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });
        
        // Check if it's a permission error
        if (e.toString().contains('permission')) {
          CustomSnackBar.show(
            context: context,
            message: 'Contacts permission is required to select the other party',
            type: SnackBarType.error,
          );
        } else {
          CustomSnackBar.show(
            context: context,
            message: 'Error loading contacts: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _refreshContacts() async {
    _searchController.clear();
    _filterContacts('');
    await _loadContacts(forceRefresh: true);
  }

  Future<void> _showContactsBottomSheet() async {
    // Clear search when opening
    _searchController.clear();
    _filterContacts('');

    // Load contacts from cache first (instant), then refresh in background if needed
    _loadCachedContacts();
    
    // If no cached contacts, load them
    if (_allContacts.isEmpty) {
      await _loadContacts();
    } else {
      // Refresh in background if cache is stale
      _contactsCacheService.loadContactsInBackground();
    }

    // Show bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildContactsBottomSheet(),
      );
    }
  }

  Widget _buildContactsBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Iconsax.people,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select ${_selectedRole == 'Remitter' ? 'Beneficiary' : 'Remitter'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose from your contacts',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Iconsax.refresh,
                        color: Colors.grey[600],
                      ),
                      onPressed: _isLoadingContacts ? null : _refreshContacts,
                      tooltip: 'Refresh Contacts',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Search Contacts',
                  hint: 'Search by name or phone',
                  prefixIcon: const Icon(Iconsax.search_normal,
                      color: Colors.grey),
                  textInputAction: TextInputAction.search,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  onChanged: _filterContacts,
                ),
              ),
              const SizedBox(height: 16),
              // Contacts list
              Expanded(
                child: _isLoadingContacts
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _filteredContacts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.people,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No contacts found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with a different term',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              final user = _getContactUser(contact);
                              final phone = _getContactPhone(contact);
                              final isInEscrow = user != null;

                              return _buildContactItem(
                                contact,
                                user,
                                phone,
                                isInEscrow,
                                onSelect: () {
                                  if (isInEscrow) {
                                    setState(() {
                                      _selectedSecondParticipant = user;
                                      _secondParticipantController.text =
                                          user.phone;
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _allContacts;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = contact.name.first.toLowerCase();
        final phone = _contactsCacheService.getContactPhone(contact);
        final displayPhone = phone.isNotEmpty ? '0$phone' : '';
        return name.contains(lowerQuery) || 
               displayPhone.contains(lowerQuery) ||
               phone.contains(lowerQuery);
      }).toList();
    });
  }

  UserModel? _getContactUser(Contact contact) {
    // Use cache service method
    return _contactsCacheService.getContactUser(contact);
  }

  String _getContactPhone(Contact contact) {
    // Use cache service method
    return _contactsCacheService.getContactPhone(contact);
  }

  Future<void> _inviteContact(Contact contact) async {
    final phone = _getContactPhone(contact);
    if (phone.isEmpty) return;

    // Format phone number for WhatsApp (Tanzania: 255XXXXXXXXX)
    final whatsappPhone = '255$phone';
    final whatsappUrl =
        'https://wa.me/$whatsappPhone?text=${Uri.encodeComponent('Hi! Join me on Mai Escrow to create secure contracts together. Download the app now!')}';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Could not open WhatsApp',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Error opening WhatsApp: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _createContract() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSecondParticipant == null) {
        CustomSnackBar.show(
          context: context,
          message: 'Please select a second participant',
          type: SnackBarType.error,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = Provider.of<UserProvider>(context, listen: false).user!;

        await _contractService.createContract(
          userId: user.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          reward: double.parse(_rewardController.text.trim()),
          role: _selectedRole,
          userFullName: user.fullName,
          userPhone: user.phone,
          secondParticipantId: _selectedSecondParticipant!.id,
          secondParticipantName: _selectedSecondParticipant!.fullName,
          secondParticipantPhone: _selectedSecondParticipant!.phone,
        );

        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Contract created successfully',
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: e.toString(),
            type: SnackBarType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Create Contract',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.grey[800],
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.grey[700],
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selection
                Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select whether you are funding the contract or receiving payment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleOption(
                        'Remitter',
                        'I will fund this contract',
                        Iconsax.wallet_money,
                        _selectedRole == 'Remitter',
                        () {
                          setState(() {
                            _selectedRole = 'Remitter';
                            _selectedSecondParticipant = null;
                            _secondParticipantController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleOption(
                        'Beneficiary',
                        'I will receive payment',
                        Iconsax.user_tick,
                        _selectedRole == 'Beneficiary',
                        () {
                          setState(() {
                            _selectedRole = 'Beneficiary';
                            _selectedSecondParticipant = null;
                            _secondParticipantController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Second Participant Selection from Contacts
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.people,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select ${_selectedRole == 'Remitter' ? 'Beneficiary' : 'Remitter'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose from your contacts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showContactsBottomSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Iconsax.people, size: 18),
                          label: const Text(
                            'Select Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedSecondParticipant != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFF2E7D32), width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _selectedSecondParticipant!.fullName[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected ${_selectedRole == 'Remitter' ? 'Beneficiary' : 'Remitter'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedSecondParticipant!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedSecondParticipant!.phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedSecondParticipant = null;
                                _secondParticipantController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Contract Details Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.document_text,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contract Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Define the terms and conditions of your agreement',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _titleController,
                        label: 'Contract Title',
                        hint: 'Enter a descriptive title for your contract',
                        prefixIcon:
                            const Icon(Iconsax.text, color: Colors.grey),
                        textInputAction: TextInputAction.next,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Contract Conditions',
                        hint:
                            '• Enter contract conditions\n• Be specific about requirements\n• Include deadlines if any',
                        prefixIcon: const Icon(
                          Iconsax.document_text,
                          color: Colors.grey,
                        ),
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        onChanged: (value) {
                          final lines = value.split('\n');
                          final bulletLines = lines.map((line) {
                            if (line.trim().isEmpty) return '';
                            if (line.startsWith('• ')) return line;
                            return '• $line';
                          }).join('\n');

                          if (value != bulletLines) {
                            _descriptionController.value = TextEditingValue(
                              text: bulletLines,
                              selection: TextSelection.collapsed(
                                offset: bulletLines.length,
                              ),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contract conditions';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _rewardController,
                        label: 'Amount to be Secured',
                        hint: 'Enter the amount in TZS',
                        prefixIcon:
                            const Icon(Iconsax.money_send, color: Colors.grey),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2E7D32),
                        const Color(0xFF16A34A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Creating Contract...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.document_text,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Create Contract',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your contract will be created securely and both parties will be notified.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    Contact contact,
    UserModel? user,
    String phone,
    bool isInEscrow, {
    VoidCallback? onSelect,
  }) {
    final contactName =
        contact.name.first.isNotEmpty ? contact.name.first : 'Unknown';
    final displayPhone = phone.isNotEmpty ? '0$phone' : 'No phone';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedSecondParticipant?.id == user?.id
              ? const Color(0xFF2E7D32)
              : Colors.grey[200]!,
          width: _selectedSecondParticipant?.id == user?.id ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isInEscrow ? (onSelect ?? () {}) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isInEscrow
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    contactName[0].toUpperCase(),
                    style: TextStyle(
                      color: isInEscrow
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          displayPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isInEscrow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'In Escrow',
                              style: TextStyle(
                                color: const Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isInEscrow)
                Icon(
                  _selectedSecondParticipant?.id == user?.id
                      ? Icons.check_circle
                      : Iconsax.arrow_right_3,
                  color: _selectedSecondParticipant?.id == user?.id
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[400],
                  size: 20,
                )
              else
                TextButton.icon(
                  onPressed: () => _inviteContact(contact),
                  icon: const Icon(
                    Iconsax.send_2,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  label: const Text(
                    'Invite',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    String role,
    String description,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: isSelected ? 2 : 1,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              role,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[800],
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF2E7D32).withOpacity(0.8)
                    : Colors.grey[600],
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
