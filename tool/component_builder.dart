import 'package:args/args.dart';
import "package:path/path.dart" as path;
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:dart_style/dart_style.dart';

final dartFormatter = DartFormatter();

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

  // build components
  print("Building components from '${path.relative(specFile.path)}'");
  final YamlMap defaults = spec["defaults"] ?? {};
  final YamlMap components = spec["components"] ?? {};
  final outputDir = Directory(args["to"]);
  outputDir.createSync(recursive: true);

  // final List<File> generatedFiles = [];
  final List<ComponentInfo> generatedComponents = [];

  for (final componentId in components.keys) {
    final component = buildComponent(componentId,
        defaults: defaults,
        schema: components[componentId],
        outputDir: outputDir);

    // generatedFiles.add(file);
    generatedComponents.add(component);
  }

  // generate components file
  buildComponentsFile(generatedComponents, outputDir.path);

  // build room components extension
  buildRoomExtension(generatedComponents, outputDir.path);

  // build component factory
  buildComponentFactory(generatedComponents, outputDir.path);
}

ComponentInfo buildComponent(String componentId,
    {required YamlMap defaults,
    required YamlMap schema,
    required Directory outputDir}) {
  print("Building '$componentId'");
  final component = ComponentInfo(id: componentId);

  // alias
  component.alias = List<String>.from(schema["alias"] as YamlList? ?? []);
  final dashedAlias = componentId.replaceAll(RegExp("_"), "-");
  if (dashedAlias != componentId) component.alias.add(dashedAlias);

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

  // room accesstor
  component.roomAccessor = componentId.toCamelCase();

  // class
  component.className = component.roomAccessor.ucFirst();
  final baseClass =
      (schema["extends"] as String?) ?? (defaults["extends"] as String?) ?? "";

  // constructor
  String constructor = buildConstructor(componentId, schema);

  // ro props
  List<String> roProps = [];
  for (final prop in [...?schema["ro"], ...?schema["rw"]]) {
    roProps.addAll(buildGetter(prop));
  }

  // rw props
  List<String> rwProps = [];
  for (final prop in schema["rw"] ?? []) {
    roProps.addAll(buildSetter(prop));
  }

  // generate source code
  component.isAbstract = schema["abstract"] as bool? ?? false;
  final classType = component.isAbstract ? "abstract class" : "class";

  String sourceCode = "// This file was auto-generated\n"
      "// Do NOT EDIT by hand\n";

  sourceCode += "\n${imports.join('\n')}\n";
  sourceCode += "\n\n";
  sourceCode += "$classType ${component.className} extends $baseClass {\n"
      "\n$constructor\n"
      "\n${roProps.join('\n')}\n"
      "\n${rwProps.join('\n')}\n"
      "\n}";

  // format
  print(" - formatting...");
  sourceCode = dartFormatter.format(sourceCode);

  // save
  final outputFile = File(path.join(outputDir.path, "$componentId.g.dart"));
  outputFile.writeAsStringSync(sourceCode);
  print(" - saved to '${path.relative(outputFile.path)}'");
  component.outputFile = outputFile;

  return component;
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

String buildConstructor(String componentId, Map schema) {
  final className = componentId.toCamelCase().ucFirst();
  final isAbstract = schema["abstract"] as bool? ?? false;
  List<String> output = [];

  // override getters
  if (!isAbstract) {
    List<String> overrides = [];
    final Map<String, dynamic> initVars = {"id": componentId};
    initVars.addAll(Map<String, dynamic>.from(schema["init_vars"] ?? {}));

    for (String varName in initVars.keys) {
      final value = initVars[varName];
      overrides.add('@override final $varName = "$value";');
    }
    output.add(overrides.join('\n'));
  }

  // constructor signature
  if (isAbstract) {
    // accept subclass schema
    output.add(
        "$className({required super.device, required super.mqttId, Map<String, Type>? schema})");
  } else {
    output.add("$className({required super.device, required super.mqttId})");
  }

  // super
  // List<Map> properties = [...?schema["ro"], ...?schema["rw"]];
  List<String> properties = [];
  for (final prop in [...?schema["ro"], ...?schema["rw"]]) {
    String name = prop["name"];
    String type = prop["type"];
    properties.add('"$name": $type');
  }

  if (isAbstract) {
    // merge subclass schema
    output.add(': super(schema: { ${properties.join(",")}, ...?schema });');
  } else {
    output.add(': super(schema: { ${properties.join(",")} });');
  }

  return output.join("\n");
}

List<String> buildGetter(YamlMap prop) {
  final result = <String>[];
  String type = prop["type"];
  String name = prop["name"];
  String accessor = name.toCamelCase();
  if (prop.containsKey("override")) {
    result.add('@override ');
  }

  result.add('$type? get $accessor => getProperty("$name") as $type?;');
  if (prop.containsKey("accessorAliasOverride")) {
    result.add(
        '@override $type? get ${prop["accessorAliasOverride"]} => getProperty("$name") as $type?;');
  }
  return result;
}

List<String> buildSetter(YamlMap prop) {
  final result = <String>[];
  String type = prop["setter_type"] ?? prop["type"];
  String name = prop["name"];

  String accessor = name.toCamelCase();
  if (prop.containsKey("override")) {
    result.add('@override ');
  }

  result.add('set $accessor($type? value) => setControl("$name", value);');
  if (prop.containsKey("accessorAliasOverride")) {
    result.add(
        '@override set ${prop["accessorAliasOverride"]}(num? value) => setControl("$name", value);');
  }
  return result;
}

void buildComponentsFile(List<ComponentInfo> components, String outputPath) {
  String output = "";
  for (final component in components) {
    final file = component.outputFile;
    if (file == null) continue;
    final importPath = path.relative(file.path, from: outputPath);
    output += "export '$importPath';\n";
  }

  final componentsFile = File(path.join(outputPath, "components.g.dart"));
  componentsFile.writeAsStringSync(output);
  print("Saved export file '${path.relative(componentsFile.path)}'");
}

void buildRoomExtension(List<ComponentInfo> componentsInfo, String outputPath) {
  final components = componentsInfo.where((c) => !c.isAbstract);

  // acessors
  final acessors = components
      .map((c) =>
          "${c.className}? get ${c.roomAccessor} => getComponentByType<${c.className}>();")
      .join("\n");

  // components getter
//   final listIfs = components.map((c) {
//     return "if (${c.roomAccessor} != null) ${c.roomAccessor}!";
//   });

//   String componentGetter =
//       "List<Component> get components => [${listIfs.join(',')}];";

//   // hasComponent
//   final hasComponentCases = components.map((c) {
//     final cases = [c.id, ...c.alias].map((id) => "case '$id':");
//     return '''
//     ${cases.join("\n")}
//     return ${c.roomAccessor} != null;
//   ''';
//   });

//   final hasComponent = '''
// bool? hasComponent(String componentId) {
//     switch (componentId) {
//       ${hasComponentCases.join("\n")}
//       default:
//         return null;
//     }
//   }
// ''';

//   // getComponent
//   final getComponentCases = components.map((c) {
//     final cases = [c.id, ...c.alias].map((id) => "case '$id':");
//     return '''
//     ${cases.join("\n")}
//     return ${c.roomAccessor} ??= ${c.className}(room: this as Room, mqttId: componentId);
//   ''';
//   });

//   final getComponent = '''
//   Component getComponent(String componentId) {
//     switch (componentId) {
//       ${getComponentCases.join("\n")}
//       default:
//         throw UnknownComponentError(componentId);
//     }
//   }
// ''';

//   // removeComponent
//   final removeComponentCases = components.map((c) {
//     final cases = [c.id, ...c.alias].map((id) => "case '$id':");
//     return '''
//     ${cases.join("\n")}
//     component = ${c.roomAccessor};
//     ${c.roomAccessor} = null;
//     break;
//   ''';
//   });

//   final removeComponent = '''
//   Component? removeComponent(String componentId) {
//     late final Component? component;
//     switch (componentId) {
//       ${removeComponentCases.join("\n")}
//       default:
//         throw UnknownComponentError(componentId);
//     }
//     return component;
//   }
// ''';

  // final content
  String content = '''
part of '../room.dart';

extension RoomComponents on Room {
  $acessors}
''';

  content = dartFormatter.format(content);
  final file = File(path.join(outputPath, "room_components.g.dart"));
  file.writeAsStringSync(content);
  print("Generated file '${path.relative(file.path)}'");
}

void buildComponentFactory(
    List<ComponentInfo> generatedComponents, String outputPath) {
  final builderSignature = "Device device, String mqttId";
  final constructorSignature = "device: device, mqttId: mqttId";

  // builders
  Map<String, String> builders = {};
  List<String> builderMapEntries = [];
  for (final component in generatedComponents) {
    if (component.isAbstract) continue;
    final name = "_build${component.className}";
    final impl =
        "${component.className} $name($builderSignature) => ${component.className}($constructorSignature);";
    builders[name] = impl;
    for (final id in [component.id, ...component.alias]) {
      builderMapEntries.add('"$id": $name');
    }
  }

  // final content
  String content = '''
import '../device.dart';
import '../component.dart';
import 'components.g.dart';


// builders
${builders.values.join("\n")}

// builder map
const Map<String, Component Function($builderSignature)> _builders = {
  ${builderMapEntries.join(",\n")}
};

class ComponentBuilder {

  static bool isValidId(String id) => _builders.containsKey(id);

  static Component fromId(String id, Device device) {
    final builder = _builders[id];
    if (builder == null) {
      throw Exception("Unknown component '\$id'");
    }

    return builder(device, id);
  }
}
''';

  content = dartFormatter.format(content);
  final file = File(path.join(outputPath, "component_builder.g.dart"));
  file.writeAsStringSync(content);
  print("Generated file '${path.relative(file.path)}'");
}

class ComponentInfo {
  ComponentInfo({
    this.id = "",
    this.className = "",
    this.alias = const [],
    this.roomAccessor = "",
    this.outputFile,
    this.isAbstract = false,
  });

  String id;
  String className;
  List<String> alias;
  String roomAccessor;
  File? outputFile;
  bool isAbstract;
}
