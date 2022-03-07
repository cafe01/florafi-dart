import 'package:args/args.dart';
import "package:path/path.dart" as path;
import 'dart:io';
import 'package:yaml/yaml.dart';

extension StringCasingExtension on String {
  String ucFirst() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
  String lcFirst() =>
      length > 0 ? '${this[0].toLowerCase()}${substring(1)}' : '';
  String toCamelCase() =>
      split('_').map((str) => str.ucFirst()).join('').lcFirst();
}

void main(List<String> arguments) {
  final argParser = ArgParser()
    ..addOption("from",
        abbr: "f",
        defaultsTo:
            path.join(path.dirname(Platform.script.path), "components.yaml"))
    ..addOption("to",
        defaultsTo: path.join(path.dirname(Platform.script.path), '..', 'lib',
            'src', 'component'));

  ArgResults args = argParser.parse(arguments);

  // open spec
  final specFile = File(args["from"]);
  final spec = loadYaml(specFile.readAsStringSync());

  // build
  print("Building components from '${path.relative(specFile.path)}'");
  final YamlMap defaults = spec["defaults"] ?? {};
  final YamlMap components = spec["components"] ?? {};
  final outputDir = Directory(args["to"]);
  outputDir.createSync(recursive: true);

  for (final componentId in components.keys) {
    buildComponent(componentId,
        defaults: defaults,
        schema: components[componentId],
        outputDir: outputDir);
  }
}

void buildComponent(String componentId,
    {required YamlMap defaults,
    required YamlMap schema,
    required Directory outputDir}) {
  print("Building '$componentId'");
  // imports
  final srcPath =
      path.join(path.dirname(Platform.script.path), "..", "lib", "src");
  final List<String> imports = [];

  for (final pkg in defaults["import"] ?? []) {
    imports.add(buildImport(pkg, srcPath, outputDir.path));
  }
  for (final pkg in schema["import"] ?? []) {
    imports.add(buildImport(pkg, srcPath, outputDir.path));
  }

  // class
  final className = componentId.toCamelCase().ucFirst();
  final baseClass =
      (schema["extends"] as String?) ?? (defaults["extends"] as String?) ?? "";

  // constructor
  String constructor = buildConstructor(className, schema["init_vars"]);

  // ro props
  List<String> roProps = [];
  for (final prop in schema["ro"] ?? []) {
    roProps.add(buildGetter(prop));
  }
  for (final prop in schema["rw"] ?? []) {
    roProps.add(buildGetter(prop));
  }

  // rw props
  List<String> rwProps = [];
  for (final prop in schema["rw"] ?? []) {
    roProps.add(buildSetter(prop));
  }

  // generate source code
  String sourceCode = "// This file was auto-generated\n"
      "// Do NOT EDIT by hand\n";

  sourceCode += "\n${imports.join('\n')}\n";
  sourceCode += "\n\n";
  sourceCode += "class $className extends $baseClass {\n"
      "\n$constructor\n"
      "\n${roProps.join('\n')}\n"
      "\n${rwProps.join('\n')}\n"
      "\n}";

  // save
  final outputFile = File(path.join(outputDir.path, "$componentId.g.dart"));
  outputFile.writeAsStringSync(sourceCode);
  print(" - saved to '${path.relative(outputFile.path)}'");

  // format
  print(" - formatting...");
  Process.runSync("dart", ["format", outputFile.path]);
}

String buildImport(String pkg, String srcPath, String outputPath) {
  if (pkg.contains(":")) {
    return "import '$pkg';";
  }

  // resolve file
  final srcFile = File(path.join(srcPath, pkg));
  if (!srcFile.existsSync()) {
    print("[!] Error: import file does not exist: ${srcFile.path}");
    exit(1);
  }

  return "import '${path.relative(srcFile.path, from: outputPath)}';";
}

String buildConstructor(String className, YamlMap? initVars) {
  String output = "$className(Room room) : super(room: room)";
  if (initVars == null || initVars.isEmpty) {
    return "$output;";
  }

  List<String> varList = [];
  for (String varName in initVars.keys) {
    final value = initVars[varName];
    varList.add('$varName = "$value";');
  }

  return "$output {\n"
      "${varList.join('\n')}"
      "\n}";
}

String buildGetter(YamlMap prop) {
  // int? get lastValue => getInt("last_value");

  String type = prop["type"];
  String name = prop["name"];
  String accessor = name.toCamelCase();
  late final String getter;

  switch (type) {
    case "int":
      getter = "getInt";
      break;
    case "double":
      getter = "getDouble";
      break;
    case "bool":
      getter = "getBool";
      break;
    case "String":
      getter = "getString";
      break;
    default:
      throw Exception("Invalid getter type '$type'");
  }

  return '$type? get $accessor => $getter("$name");';
}

String buildSetter(YamlMap prop) {
  // set fooBar(int? value) => setControl("foo_bar", value);

  String type = prop["type"];
  String name = prop["name"];
  String accessor = name.toCamelCase();
  return 'set $accessor($type? value) => setControl("$name", value);';
}
