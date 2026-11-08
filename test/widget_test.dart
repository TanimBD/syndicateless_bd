import 'package:flutter_test/flutter_test.dart';
import 'package:synlessbd/core/app_state.dart';
import 'package:synlessbd/data/bd_locations.dart';
import 'package:synlessbd/data/sectors.dart';
import 'package:synlessbd/screens/prices_page.dart';

void main() {
  test('median', () {
    expect(median([3, 1, 2]), 2);
    expect(median([4, 1, 2, 3]), 2.5);
    expect(median([]), 0);
  });

  test('bangla digits', () {
    expect(bnNum(2026), '২০২৬');
  });

  test('all 64 districts present', () {
    expect(kDistricts.length, 64);
  });

  test('sector ids are unique', () {
    final ids = kSectors.map((s) => s.id).toSet();
    expect(ids.length, kSectors.length);
  });
}
