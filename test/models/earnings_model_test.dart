import 'package:flutter_test/flutter_test.dart';
import 'package:toriino_todd/model/earnings/earnings_model.dart';

void main() {
  group('EarningsSummaryResponse.fromJson', () {
    test('round-trip with full data', () {
      final json = {
        'currentMonth': {
          'userId': 'u1',
          'periodKey': '2024-01',
          'amount': 500.0,
          'sessions': 5,
        },
        'totalEarnings': 5000.0,
        'monthlyBreakdown': [],
      };
      final result = EarningsSummaryResponse.fromJson(json);
      expect(result.totalEarnings, 5000.0);
    });

    test('missing currentMonth key does not throw', () {
      final result = EarningsSummaryResponse.fromJson({'totalEarnings': 0.0});
      expect(result.totalEarnings, 0.0);
    });
  });
}
