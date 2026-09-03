import 'package:flutter/foundation.dart';

/// Centralized session manager for SENTINEL.
/// Holds authoritative session state: User ID, Login Mode ('normal' vs 'ghost'),
/// display balance (real or shadow), balance masking, and transaction history.
class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _userId;
  String _loginMode = 'normal'; // 'normal' | 'ghost'
  double _balance = 0.0;
  bool _isBalanceMasked = false;
  final List<Map<String, dynamic>> _recentTransactions = [];

  // Getters
  String? get userId => _userId;
  String get loginMode => _loginMode;
  bool get isAuthenticated => _userId != null;
  bool get isGhostMode => _loginMode == 'ghost';
  double get balance => _balance;
  bool get isBalanceMasked => _isBalanceMasked;
  List<Map<String, dynamic>> get recentTransactions =>
      List.unmodifiable(_recentTransactions);

  String get displayBalanceText => '₹${_balance.toStringAsFixed(2)}';

  /// Start an authenticated session
  void startSession({
    required String userId,
    required String loginMode,
    required double balance,
    List<Map<String, dynamic>>? initialTransactions,
  }) {
    _userId = userId;
    _loginMode = loginMode;
    _balance = balance;
    _isBalanceMasked = false;
    _recentTransactions.clear();
    if (initialTransactions != null) {
      _recentTransactions.addAll(initialTransactions);
    }
    notifyListeners();
  }

  /// Toggle privacy balance mask (if needed)
  void toggleBalanceMask() {
    _isBalanceMasked = !_isBalanceMasked;
    notifyListeners();
  }

  /// Update balance (shadow balance in Ghost Mode, real balance in Normal Mode)
  void updateBalance(double newBalance) {
    _balance = newBalance;
    notifyListeners();
  }

  /// Add a newly processed transaction
  void addTransaction(Map<String, dynamic> tx) {
    _recentTransactions.insert(0, tx);
    notifyListeners();
  }

  /// Set transaction history from backend
  void setTransactions(List<Map<String, dynamic>> txs) {
    _recentTransactions.clear();
    _recentTransactions.addAll(txs);
    notifyListeners();
  }

  /// Wipes all session state completely (used on Logout and Safe Exit)
  void clearSession() {
    _userId = null;
    _loginMode = 'normal';
    _balance = 0.0;
    _isBalanceMasked = false;
    _recentTransactions.clear();
    notifyListeners();
  }
}

final sessionManager = SessionManager();
