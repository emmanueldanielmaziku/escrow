import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contract_model.dart';
import '../utils/fee_calculator.dart';

enum ContractSummaryMode {
  fundingSummary, // Before funding
  transactionReceipt, // After successful funding
}

class ContractSummaryBottomSheet extends StatefulWidget {
  final ContractModel contract;
  final ContractSummaryMode mode;
  final VoidCallback? onPayNow;
  final VoidCallback? onCancel;

  const ContractSummaryBottomSheet({
    super.key,
    required this.contract,
    required this.mode,
    this.onPayNow,
    this.onCancel,
  });

  /// Shows the bottom sheet in funding summary mode
  static Future<void> showFundingSummary({
    required BuildContext context,
    required ContractModel contract,
    required VoidCallback onPayNow,
    required VoidCallback onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContractSummaryBottomSheet(
        contract: contract,
        mode: ContractSummaryMode.fundingSummary,
        onPayNow: onPayNow,
        onCancel: onCancel,
      ),
    );
  }

  /// Shows the bottom sheet in transaction receipt mode
  static Future<void> showReceipt({
    required BuildContext context,
    required ContractModel contract,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContractSummaryBottomSheet(
        contract: contract,
        mode: ContractSummaryMode.transactionReceipt,
      ),
    );
  }

  @override
  State<ContractSummaryBottomSheet> createState() =>
      _ContractSummaryBottomSheetState();
}

class _ContractSummaryBottomSheetState
    extends State<ContractSummaryBottomSheet> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final fee = FeeCalculator.calculateFee(widget.contract.reward);
    final total = FeeCalculator.calculateTotal(widget.contract.reward);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final contractDate = dateFormat.format(widget.contract.createdAt);

    return Stack(
      children: [
        // Blur overlay background
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        // Bottom sheet content
        DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // RepaintBoundary for image capture (excludes buttons)
                      RepaintBoundary(
                        key: _repaintBoundaryKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Receipt Container - Only for receipt mode
                            if (widget.mode ==
                                ContractSummaryMode.transactionReceipt)
                              _buildReceiptCard(
                                context: context,
                                contractDate: contractDate,
                                fee: fee,
                                total: total,
                              )
                            else
                              // Transaction Summary
                              Column(
                                children: [
                                  Center(
                                    child: Text(
                                      'Transaction Summary',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailsCard(
                                    context: context,
                                    contractDate: contractDate,
                                    fee: fee,
                                    total: total,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons (outside RepaintBoundary so not captured)
                      if (widget.mode ==
                          ContractSummaryMode.fundingSummary) ...[
                        _buildFundingSummaryActions(context),
                      ] else ...[
                        _buildReceiptActions(context),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReceiptCard({
    required BuildContext context,
    required String contractDate,
    required double fee,
    required double total,
  }) {
    final dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final receiptDateTime = dateTimeFormat.format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/icons/green.png',
            scale: 25,
          ),
          const SizedBox(height: 12),

          // Company Name
          const Text(
            'Mai Escrow',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Secure Payment Escrow Service',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              letterSpacing: 0.3,
            ),
          ),

          // Dashed Line
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              painter: DashedLinePainter(),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),

          // Receipt Title
          const Text(
            'TRANSACTION RECEIPT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Receipt Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Receipt No:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  widget.contract.id.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date & Time:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                receiptDateTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Dashed Line
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              painter: DashedLinePainter(),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),

          // Transaction Details
          _buildReceiptRow('Contract Title', widget.contract.title),
          const SizedBox(height: 12),
          _buildReceiptRow('Remitter', widget.contract.remitterName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildReceiptRow(
              'Beneficiary', widget.contract.beneficiaryName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildReceiptRow('Contract Date', contractDate),

          // Dashed Line
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              painter: DashedLinePainter(),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),

          // Amount Details
          _buildReceiptAmountRow('Contract Amount', widget.contract.reward),
          const SizedBox(height: 8),
          _buildReceiptAmountRow('Service Fee', fee),

          // Solid Line
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            color: Colors.grey[400],
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PAID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                FeeCalculator.formatTsh(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),

          // Dashed Line
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomPaint(
              painter: DashedLinePainter(),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),

          // Footer
          Text(
            'Thank you for using Mai Escrow!',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'This is an electronic receipt',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptAmountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          FeeCalculator.formatTsh(amount),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required BuildContext context,
    required String contractDate,
    required double fee,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            label: 'Contract ID',
            value: widget.contract.id,
            icon: Icons.tag_outlined,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Contract Date',
            value: contractDate,
            icon: Icons.calendar_today_outlined,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Remitter Name',
            value: widget.contract.remitterName ?? 'N/A',
            icon: Icons.person_outline,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Beneficiary Name',
            value: widget.contract.beneficiaryName ?? 'N/A',
            icon: Icons.person_outline,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Contract Title',
            value: widget.contract.title,
            icon: Icons.description_outlined,
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Contract Amount',
            value: FeeCalculator.formatTsh(widget.contract.reward),
            icon: Icons.account_balance_wallet_outlined,
            valueStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const Divider(height: 16),
          _buildDetailRow(
            label: 'Contract Fee',
            value: FeeCalculator.formatTsh(fee),
            icon: Icons.receipt_outlined,
            valueStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const Divider(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _buildDetailRow(
              label: widget.mode == ContractSummaryMode.fundingSummary
                  ? 'Total Amount to be Paid'
                  : 'Total Paid',
              value: FeeCalculator.formatTsh(total),
              icon: Icons.payment_outlined,
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundingSummaryActions(BuildContext context) {
    return Column(
      children: [
        // View full pricing link
        InkWell(
          onTap: () async {
            final url = Uri.parse('https://maiescrow.com/#transaction-fees');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View full pricing',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pay Now Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.onPayNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Pay Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: widget.onCancel ?? () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptActions(BuildContext context) {
    return Column(
      children: [
        // Share Receipt Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isSharing ? null : () => _shareReceipt(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(
              _isSharing ? 'Sharing...' : 'Share Receipt',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Wait for the widget to render
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture the widget as an image
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/contract_receipt_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      // Share the image
      final XFile xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Contract Receipt - ${widget.contract.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing receipt: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
