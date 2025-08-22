/// Simple embedding status management - only loading and completed states
class EmbeddingStatus {
  static bool _isComplete = false;
  static bool _isGenerating = false;
  static final List<Function()> _listeners = [];

  static bool get isComplete => _isComplete;
  static bool get isGenerating => _isGenerating;

  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static void startGeneration() {
    _isGenerating = true;
    _isComplete = false;
    _notifyListeners();
  }

  static void markComplete() {
    _isGenerating = false;
    _isComplete = true;
    _notifyListeners();
  }

  static void reset() {
    _isGenerating = false;
    _isComplete = false;
    _notifyListeners();
  }
}
