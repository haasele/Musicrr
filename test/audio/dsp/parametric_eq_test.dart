import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for Parametric EQ logic
/// Note: These test the EQ logic, not the native implementation
/// For native tests, see instrumentation tests
void main() {
  group('Parametric EQ Logic Tests', () {
    test('EQ band frequency range validation', () {
      // Test frequency bounds
      expect(() => _validateFrequency(20.0), returnsNormally);
      expect(() => _validateFrequency(20000.0), returnsNormally);
      expect(() => _validateFrequency(19.0), throwsException);
      expect(() => _validateFrequency(20001.0), throwsException);
    });

    test('EQ band gain range validation', () {
      // Test gain bounds (-12dB to +12dB)
      expect(() => _validateGain(-12.0), returnsNormally);
      expect(() => _validateGain(12.0), returnsNormally);
      expect(() => _validateGain(-13.0), throwsException);
      expect(() => _validateGain(13.0), throwsException);
    });

    test('EQ band Q factor validation', () {
      // Test Q bounds (0.1 to 10.0)
      expect(() => _validateQ(0.1), returnsNormally);
      expect(() => _validateQ(10.0), returnsNormally);
      expect(() => _validateQ(0.05), throwsException);
      expect(() => _validateQ(11.0), throwsException);
    });

    test('Filter type selection by frequency', () {
      expect(_getFilterType(50.0), equals('low_shelf'));
      expect(_getFilterType(1000.0), equals('peak'));
      expect(_getFilterType(15000.0), equals('high_shelf'));
    });

    test('Gain calculation (dB to linear)', () {
      expect(_dbToLinear(0.0), closeTo(1.0, 0.01));
      expect(_dbToLinear(6.0), closeTo(1.995, 0.01));
      expect(_dbToLinear(-6.0), closeTo(0.501, 0.01));
      expect(_dbToLinear(12.0), closeTo(3.981, 0.01));
    });

    test('Limiter threshold calculation', () {
      final samples = [0.5, 0.8, 1.2, 0.3];
      final limited = _applyLimiter(samples, 0.95);
      
      expect(limited.any((s) => s.abs() > 0.95), isFalse);
      expect(limited[2], closeTo(0.95, 0.01)); // Clipped to threshold
    });
  });
}

// Helper functions for testing EQ logic
void _validateFrequency(double frequency) {
  if (frequency < 20.0 || frequency > 20000.0) {
    throw Exception('Frequency out of range');
  }
}

void _validateGain(double gain) {
  if (gain < -12.0 || gain > 12.0) {
    throw Exception('Gain out of range');
  }
}

void _validateQ(double q) {
  if (q < 0.1 || q > 10.0) {
    throw Exception('Q factor out of range');
  }
}

String _getFilterType(double frequency) {
  if (frequency < 100.0) return 'low_shelf';
  if (frequency > 10000.0) return 'high_shelf';
  return 'peak';
}

double _dbToLinear(double db) {
  return 10.0.pow(db / 20.0);
}

List<double> _applyLimiter(List<double> samples, double threshold) {
  final maxSample = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
  
  if (maxSample <= threshold) {
    return samples;
  }
  
  final limitingGain = threshold / maxSample;
  return samples.map((s) => (s * limitingGain).clamp(-1.0, 1.0)).toList();
}

extension on double {
  double pow(double exponent) {
    return math.pow(this, exponent).toDouble();
  }
}
