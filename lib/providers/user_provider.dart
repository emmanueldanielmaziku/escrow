import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void updateUserBalance(double newBalance) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        fullName: _user!.fullName,
        phone: _user!.phone,
        email: _user!.email,
        walletNumber: _user!.walletNumber,
        balance: newBalance,
        totalContracts: _user!.totalContracts,
        totalInvitations: _user!.totalInvitations,
      );
      notifyListeners();
    }
  }

  void updateContractCount(int newCount) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        fullName: _user!.fullName,
        phone: _user!.phone,
        email: _user!.email,
        walletNumber: _user!.walletNumber,
        balance: _user!.balance,
        totalContracts: newCount,
        totalInvitations: _user!.totalInvitations,
      );
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
