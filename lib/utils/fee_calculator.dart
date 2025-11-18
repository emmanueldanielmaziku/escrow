/// Utility class for calculating contract fees based on amount
class FeeCalculator {
  /// Calculates the fee based on the contract amount
  /// 
  /// Fee structure:
  /// - Tsh 1,000 – Tsh 10,000 → fee = Tsh 1,000
  /// - Tsh 10,001 – Tsh 100,000 → fee = Tsh 2,000
  /// - Tsh 100,001 – Tsh 1,000,000 → fee = Tsh 3,000
  /// - Tsh 1,000,001 – Tsh 2,500,000 → fee = Tsh 4,000
  /// - Tsh 2,500,001+ → fee = 0.5% of amount
  static double calculateFee(double amount) {
    if (amount >= 2500001) {
      // 0.5% of amount for amounts >= Tsh 2,500,001
      return amount * 0.005;
    } else if (amount >= 1000001) {
      // Tsh 4,000 for amounts between Tsh 1,000,001 and Tsh 2,500,000
      return 4000.0;
    } else if (amount >= 100001) {
      // Tsh 3,000 for amounts between Tsh 100,001 and Tsh 1,000,000
      return 3000.0;
    } else if (amount >= 10001) {
      // Tsh 2,000 for amounts between Tsh 10,001 and Tsh 100,000
      return 2000.0;
    } else if (amount >= 1000) {
      // Tsh 1,000 for amounts between Tsh 1,000 and Tsh 10,000
      return 1000.0;
    } else {
      // No fee for amounts below Tsh 1,000
      return 0.0;
    }
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
        formatted = ',' + formatted;
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

