typedef FluxRow = Map<String, String?>;

class FluxSeries {
  final String key;
  final List<FluxRow> data = [];

  FluxSeries(this.key);
}

Future<List<FluxSeries>> parseFluxSeries(
    {Stream<String>? stream, String? csv}) async {
  assert(stream != null || csv != null);

  final series = <FluxSeries>[];

  List<String>? defaults;
  List<String>? headers;

  bool hasAnnotation = false;
  String currentTable = "";

  const skipColumns = ["result", "_start", "_stop"];

  void createNewSeries(FluxRow row) {
    const skipKeyField = ["result", "_time", "_start", "_stop", "_value"];
    final List<String> keyParts = [];
    row.forEach((key, value) {
      if (!skipKeyField.contains(key) && value != null) keyParts.add(value);
    });

    series.add(FluxSeries(keyParts.join('.')));
  }

  void parseLine(String line) {
    // begin of new schema
    if (line.isEmpty) {
      defaults = null;
      headers = null;
      return;
    }

    // annotations
    if (line.startsWith("#")) {
      hasAnnotation = true;

      // defaults
      if (line.startsWith("#default")) defaults = line.split(",");

      return;
    }

    // columns
    final cells = line.split(",");

    // headers
    if (headers == null) {
      headers = cells;
      return;
    }

    // row
    final FluxRow row = {};
    String table = "";

    for (var i = hasAnnotation ? 1 : 0; i < cells.length; i++) {
      String header = headers![i];

      // table column
      if (header == "table") {
        table = cells[i];
        continue;
      }

      // skipped columns
      if (skipColumns.contains(header)) continue;

      // cell value
      String? cell = cells[i].isEmpty ? null : cells[i];

      if (cell == null && defaults != null && defaults![i].isNotEmpty) {
        cell = defaults![i];
      }

      row[header] = cell;
    }

    // add to series
    if (series.isEmpty || table != currentTable) {
      currentTable = table;
      print("New series: $table (${series.length})");
      createNewSeries(row);
      print(" - key: ${series.last.key}");
    }

    if (row["_time"] == null) {
      throw Exception("Missing '_time' field. ($line)");
    }

    series.last.data.add(row);
  }

  if (stream != null) {
    await for (final line in stream) {
      parseLine(line);
    }
  } else if (csv != null) {
    for (var line in csv.split("\n")) {
      // print("Line: (${line.trim()})");
      parseLine(line.trim());
    }
  }

  return series;
}
