import 'dart:convert';
import 'dart:io';
import 'package:florafi/src/flux_utils.dart';
import 'package:test/test.dart';

void main() {
  group("parseFluxResult()", () {
    late Stream<String> lines;

    setUp(() {
      final file = File('test/flux_result.csv');
      lines = file.openRead().transform(utf8.decoder).transform(LineSplitter());
    });

    test('handles multiple tables/schemas', () async {
      final series = await parseFluxSeries(stream: lines);
      expect(series.length, 4);
      expect(series[0].key, 'room0.humidity.2');
      expect(series[1].key, 'room1.light.2');
      expect(series[2].key, 'room2.temperature.2');
      expect(series[3].key, 'room3.temperature.2');

      expect(series[0].data.length, 4);
      expect(series[1].data.length, 3);
      expect(series[2].data.length, 4);
      expect(series[3].data.length, 4);

      expect(series[0].data.first["_value"], "67.6");
      expect(series[0].data.first["_time"].toString(), "2022-04-04T15:40:00Z");
    });
  });
}
