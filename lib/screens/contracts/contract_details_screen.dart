import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/contract_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/status_badge.dart';

class ContractDetailsScreen extends StatefulWidget {
  final ContractModel contract;
  final int initialTabIndex;

  const ContractDetailsScreen({
    super.key,
    required this.contract,
    this.initialTabIndex = 0,
  });

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _receiptController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  late ContractModel contract;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    contract = widget.contract;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadPaymentProof() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // TODO: Implement upload logic here
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.paymentUploadedMsg)),
        );
        setState(() {
          _isLoading = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitReceiptNumber() async {
    if (_receiptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a receipt number')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // TODO: Implement receipt submission logic here
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.paymentUploadedMsg)),
        );
        setState(() {
          _isLoading = false;
          _receiptController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Please make the payment using one of the following methods:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Mobile Money Options
              _buildPaymentOption(
                'Vodacom M-Pesa',
                'Send money to: 0755 123 456',
                Icons.phone_android,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'Airtel Money',
                'Send money to: 0655 789 012',
                Icons.phone_android,
                Colors.red.shade700,
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'Tigo Pesa',
                'Send money to: 0655 345 678',
                Icons.phone_android,
                Colors.blue,
              ),

              const SizedBox(height: 24),
              const Text(
                'After making the payment, please upload the payment screenshot or enter the receipt number below.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),

              // Upload options
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Screenshot'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReceiptInputDialog();
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Enter Receipt'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Receipt Number'),
        content: CustomTextField(
          controller: _receiptController,
          label: 'Receipt Number',
          hint: 'Enter the payment receipt number',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReceiptNumber();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    final dateFormat = DateFormat("MMM d, yyyy 'at' h:mm a");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Payment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contract Header
                GlassmorphismCard(
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusBadge(status: contract.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        contract.description,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contract Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'TSh ${currencyFormat.format(contract.amount)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contract Timeline
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contract Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineItem(
                        'Created',
                        dateFormat.format(contract.createdAt.toDate()),
                        Icons.create,
                        Colors.blue,
                        true,
                      ),
                      if (contract.status != AppConstants.dormant &&
                          contract.status != AppConstants.declined)
                        _buildTimelineItem(
                          'Accepted',
                          contract.acceptedAt != null
                              ? dateFormat.format(contract.acceptedAt!.toDate())
                              : 'Pending',
                          Icons.check_circle,
                          Colors.green,
                          contract.acceptedAt != null,
                        ),
                      if (contract.status ==
                              AppConstants.awaitingAdminApproval ||
                          contract.status == AppConstants.active ||
                          contract.status == AppConstants.closed ||
                          contract.status == AppConstants.terminated)
                        _buildTimelineItem(
                          'Payment Submitted',
                          contract.proofOfPaymentUrl != null ||
                                  contract.receiptNumber != null
                              ? 'Completed'
                              : 'Pending',
                          Icons.payment,
                          Colors.orange,
                          contract.proofOfPaymentUrl != null ||
                              contract.receiptNumber != null,
                        ),
                      if (contract.status == AppConstants.active ||
                          contract.status == AppConstants.closed ||
                          contract.status == AppConstants.terminated)
                        _buildTimelineItem(
                          'Payment Approved',
                          'Completed',
                          Icons.verified,
                          Colors.purple,
                          true,
                        ),
                      if (contract.withdrawalRequested)
                        _buildTimelineItem(
                          'Withdrawal Requested',
                          'Pending Confirmation',
                          Icons.account_balance_wallet,
                          Colors.teal,
                          true,
                        ),
                      if (contract.status == AppConstants.closed)
                        _buildTimelineItem(
                          'Contract Completed',
                          'Funds Released',
                          Icons.done_all,
                          Colors.green,
                          true,
                        ),
                      if (contract.status == AppConstants.terminated)
                        _buildTimelineItem(
                          'Contract Terminated',
                          'Withdrawal Declined',
                          Icons.cancel,
                          Colors.red,
                          true,
                        ),
                      if (contract.status == AppConstants.declined)
                        _buildTimelineItem(
                          'Contract Declined',
                          'Invitation Rejected',
                          Icons.cancel,
                          Colors.red,
                          true,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contract Parties
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contract Parties',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Creator',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  contract.creatorId == 'currentUserId'
                                      ? 'You'
                                      : 'User ID: ${contract.creatorId.substring(0, 6)}...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child:
                                const Icon(Icons.person, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invitee',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  contract.creatorId != 'currentUserId'
                                      ? 'You'
                                      : 'User ID: ${contract.inviteeId.substring(0, 6)}...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (_shouldShowActionButtons(contract))
                  _buildActionButtons(contract),
              ],
            ),
          ),

          // Payment Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Status
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Contract Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'TSh ${currencyFormat.format(contract.amount)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          StatusBadge(status: contract.status),
                        ],
                      ),
                      if (contract.receiptNumber != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Receipt Number:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              contract.receiptNumber!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Instructions (only for creator when status is not_funded)
                if (contract.creatorId == 'currentUserId' &&
                    contract.status == AppConstants.notFunded)
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Please make the payment using one of the following methods:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Mobile Money Options
                        _buildPaymentOption(
                          'Vodacom M-Pesa',
                          'Send money to: 0755 123 456',
                          Icons.phone_android,
                          Colors.red,
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'Airtel Money',
                          'Send money to: 0655 789 012',
                          Icons.phone_android,
                          Colors.red.shade700,
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'Tigo Pesa',
                          'Send money to: 0655 345 678',
                          Icons.phone_android,
                          Colors.blue,
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'After making the payment, please upload the payment screenshot or enter the receipt number below.',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Upload Payment Proof (only for creator when status is not_funded)
                if (contract.creatorId == 'currentUserId' &&
                    contract.status == AppConstants.notFunded)
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Payment Proof',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image Upload
                        GestureDetector(
                          onTap: _isLoading ? null : _pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload,
                                        size: 48,
                                        color: Colors.grey.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Tap to upload payment screenshot',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading || _selectedImage == null
                                ? null
                                : _uploadPaymentProof,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Upload Screenshot'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Receipt Number
                        CustomTextField(
                          controller: _receiptController,
                          label: 'Receipt Number',
                          hint: 'Enter the payment receipt number',
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading || _receiptController.text.isEmpty
                                    ? null
                                    : _submitReceiptNumber,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit Receipt Number'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Payment Proof (when already uploaded)
                if (contract.proofOfPaymentUrl != null)
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Proof',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            contract.proofOfPaymentUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.withOpacity(0.1),
                                child: const Center(
                                  child: Text('Failed to load image'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? color : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.grey.shade700 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowActionButtons(ContractModel contract) {
    if (contract.creatorId == 'currentUserId' &&
        contract.status == AppConstants.notFunded) {
      return true; // Show Fund button for creator when not funded
    } else if (contract.creatorId != 'currentUserId' &&
        contract.status == AppConstants.active &&
        !contract.withdrawalRequested) {
      return true; // Show Withdraw button for invitee when active
    } else if (contract.creatorId == 'currentUserId' &&
        contract.status == AppConstants.active &&
        contract.withdrawalRequested) {
      return true; // Show Confirm/Decline buttons for creator when withdrawal requested
    }
    return false;
  }

  Widget _buildActionButtons(ContractModel contract) {
    if (contract.creatorId == 'currentUserId' &&
        contract.status == AppConstants.notFunded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _showPaymentBottomSheet();
          },
          child: const Text('Fund Contract'),
        ),
      );
    } else if (contract.creatorId != 'currentUserId' &&
        contract.status == AppConstants.active &&
        !contract.withdrawalRequested) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement withdrawal request logic here
          },
          child: const Text('Request Withdrawal'),
        ),
      );
    } else if (contract.creatorId == 'currentUserId' &&
        contract.status == AppConstants.active &&
        contract.withdrawalRequested) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement withdrawal confirmation logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement withdrawal decline logic here
              },
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
