import 'dart:math';

/// Ventana móvil de muestras en milisegundos con percentiles.
class LatencyStats {
  LatencyStats([this.window = 100]);

  final int window;
  final List<double> _recent = [];
  final List<double> all = []; // toda la sesión, para exportar

  void add(double ms) {
    _recent.add(ms);
    all.add(ms);
    if (_recent.length > window) _recent.removeAt(0);
  }

  void clear() {
    _recent.clear();
    all.clear();
  }

  int get count => _recent.length;
  double get last => _recent.isEmpty ? 0 : _recent.last;
  double get mean => _recent.isEmpty ? 0 : _recent.reduce((a, b) => a + b) / _recent.length;
  double get p50 => percentile(_recent, 50);
  double get p95 => percentile(_recent, 95);

  static double percentile(List<double> xs, double p) {
    if (xs.isEmpty) return 0;
    final s = [...xs]..sort();
    final idx = ((p / 100) * (s.length - 1)).round();
    return s[max(0, min(s.length - 1, idx))];
  }
}
