/// Utility class for calculating contract fees based on amount
class FeeCalculator {
  static const double _depositFeeRate = 0.008; // 0.8%

  /// Calculates the fee based on the contract amount
  ///
  /// Fee policy:
  /// - Deposit fee = 0.8% of amount
  static double calculateFee(double amount) {
    if (amount <= 0) return 0.0;
    return amount * _depositFeeRate;
  }

  /// Formats amount as Tanzanian Shilling with comma separators
  /// Example: 25000.0 -> "Tsh 25,000"
  static String formatTsh(double amount) {
    final amountStr = amount.toStringAsFixed(0);
    final parts = amountStr.split('.');
    final integerPart = parts[0];
    
    // Add comma separators
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = ',$formatted';
        count = 0;
      }
      formatted = integerPart[i] + formatted;
      count++;
    }
    
    return 'Tsh $formatted';
  }

  /// Calculates total amount (amount + fee)
  static double calculateTotal(double amount) {
    return amount + calculateFee(amount);
  }
}

