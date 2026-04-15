/// Tracks whether the user has already passed the PIN check
/// during the current app session (in-memory only, resets on restart).
class PinSession {
  PinSession._();
  static final PinSession instance = PinSession._();

  bool _verified = false;

  bool get verified => _verified;

  void markVerified() => _verified = true;

  /// Call on sign-out so the next launch requires PIN again.
  void reset() => _verified = false;
}
