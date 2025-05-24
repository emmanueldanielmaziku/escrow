import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String displayText;

    switch (status) {
      case AppConstants.dormant:
        backgroundColor = Colors.grey;
        displayText = 'Pending';
        break;
      case AppConstants.notFunded:
        backgroundColor = Colors.amber;
        textColor = Colors.black;
        displayText = 'Not Funded';
        break;
      case AppConstants.awaitingAdminApproval:
        backgroundColor = Colors.blue;
        displayText = 'Awaiting Approval';
        break;
      case AppConstants.active:
        backgroundColor = Colors.green;
        displayText = 'Active';
        break;
      case AppConstants.closed:
        backgroundColor = Colors.purple;
        displayText = 'Closed';
        break;
      case AppConstants.terminated:
        backgroundColor = Colors.red;
        displayText = 'Terminated';
        break;
      case AppConstants.declined:
        backgroundColor = Colors.red.shade300;
        displayText = 'Declined';
        break;
      default:
        backgroundColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
