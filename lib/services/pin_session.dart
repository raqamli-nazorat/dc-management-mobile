// pin_session.dart — ChangeNotifier qiling
import 'package:flutter/material.dart';

class PinSession extends ChangeNotifier {
  PinSession._();
  static final PinSession instance = PinSession._();

  bool _verified = false;
  DateTime? _verifiedAt;
  static const _expiry = Duration(hours: 1);

  bool get verified {
    if (!_verified) return false;
    if (_verifiedAt == null) return false;
    if (DateTime.now().difference(_verifiedAt!) > _expiry) {
      _verified = false;
      _verifiedAt = null;
      return false;
    }
    return true;
  }

  void markVerified() {
    _verified = true;
    _verifiedAt = DateTime.now();
    notifyListeners(); // router refresh
  }

  void reset() {
    _verified = false;
    _verifiedAt = null;
    notifyListeners();
  }
}