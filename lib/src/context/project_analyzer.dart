import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import '../models/context_models.dart';

/// Analyzes project structure and context for AI assistance
class ProjectAnalyzer {
  final String projectPath;

  ProjectAnalyzer({required this.projectPath});

  /// Complete project context analysis
  Future<ProjectContext> analyzeProjectContext() async {
    final dependencies = await _analyzeDependencies();
    final imports = await _analyzeImports();
    final classes = await _analyzeClasses();
    final dartCoreApis = await _analyzeDartCoreUsage();
    final externalPackages = await _findPackageUsage();
    final deprecatedApis = await _findDeprecatedUsage();
    final codeStyle = await _analyzeCodeStyle();
    final typeSystem = await _analyzeTypeSystem();
    final errorPatterns = await _analyzeErrorPatterns();

    return ProjectContext(
      projectPath: projectPath,
      dependencies: dependencies,
      imports: imports,
      classes: classes,
      dartCoreApis: dartCoreApis,
      externalPackages: externalPackages,
      deprecatedApis: deprecatedApis,
      codeStyle: codeStyle,
      typeSystem: typeSystem,
      errorPatterns: errorPatterns,
    );
  }

  /// Analyze project dependencies from pubspec.yaml
  Future<List<String>> _analyzeDependencies() async {
    try {
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (!await pubspecFile.exists()) {
        return [];
      }

      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');
      
      final dependencies = <String>[];
      bool inDependencies = false;
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('dependencies:')) {
          inDependencies = true;
        } else if (trimmed.startsWith('dev_dependencies:') || 
                   trimmed.startsWith('dependency_overrides:')) {
          inDependencies = false;
        } else if (inDependencies && trimmed.startsWith(':')) {
          final dep = trimmed.substring(1).trim();
          final depName = dep.split(':')[0].replaceAll("'", "").replaceAll('"', "").trim();
          if (depName.isNotEmpty) {
            dependencies.add(depName);
          }
        }
      }
      
      return dependencies;
    } catch (e) {
      return [];
    }
  }

  /// Analyze import patterns across all Dart files
  Future<Map<String, List<String>>> _analyzeImports() async {
    final imports = <String, List<String>>{};
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');
        final fileImports = <String>[];
        
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('import ')) {
            fileImports.add(trimmed);
          }
        }
        
        if (fileImports.isNotEmpty) {
          imports[file.path] = fileImports;
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return imports;
  }

  /// Analyze class definitions and structure
  Future<Map<String, ClassInfo>> _analyzeClasses() async {
    final classes = <String, ClassInfo>{};
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final className = _extractClassName(file.path);
        if (className != null) {
          classes[className] = ClassInfo(
            name: className,
            filePath: file.path,
            methods: _extractMethods(content),
            properties: _extractProperties(content),
            constructors: _extractConstructors(content),
            superClass: _extractSuperClass(content),
            interfaces: _extractInterfaces(content),
          );
        }
      } catch (e) {
        // Skip files that can't be analyzed
      }
    }
    
    return classes;
  }

  /// Find Dart core API usage
  Future<List<String>> _analyzeDartCoreUsage() async {
    final dartCoreApis = <String>{};
    final coreApis = [
      'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Future',
      'Stream', 'DateTime', 'Duration', 'Uri', 'File', 'Directory',
      'http', 'async', 'convert', 'io', 'math'
    ];
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        for (final api in coreApis) {
          if (content.contains(api)) {
            dartCoreApis.add(api);
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return dartCoreApis.toList();
  }

  /// Find external package usage
  Future<List<String>> _findPackageUsage() async {
    final packages = <String>{};
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final packagesInFile = _findLibrariesInContent(content);
        packages.addAll(packagesInFile);
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return packages.toList();
  }

  /// Find libraries in Dart content using analyzer package
  List<String> _findLibrariesInContent(String content) {
    try {
      // Parse the dart string
      final parseResult = parseString(
        content: content,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      
      // Get all directives (imports, exports, etc.)
      final directives = parseResult.unit.directives;
      
      // Only retain the imports
      final importDirectives = directives.whereType<ImportDirective>();
      
      // Extract package names from imports
      final libraries = <String>[];
      for (final directive in importDirectives) {
        final name = _extractPackageName(directive);
        if (name != null) {
          libraries.add(name);
        }
      }
      
      return libraries;
    } catch (e) {
      // If parsing fails, fall back to simple string search
      return _findPackagesWithSimpleSearch(content);
    }
  }

  /// Extract package name from import directive
  String? _extractPackageName(ImportDirective importDirective) {
    final uri = importDirective.uri.stringValue;
    if (uri != null && uri.startsWith('package:')) {
      return uri
          .replaceAll('package:', '')
          .replaceFirst('/', ':')
          .replaceAll('/', '.')
          .replaceAll('.dart', '');
    }
    return null;
  }

  /// Fallback method using simple string search
  List<String> _findPackagesWithSimpleSearch(String content) {
    final packages = <String>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('import ')) {
        // Look for package: prefix
        if (trimmedLine.contains('package:')) {
          final startIndex = trimmedLine.indexOf('package:') + 8;
          final endIndex = trimmedLine.indexOf(';', startIndex);
          if (startIndex > 8 && endIndex > startIndex) {
            final packageName = trimmedLine.substring(startIndex, endIndex);
            packages.add(packageName);
          }
        }
      }
    }
    
    return packages;
  }

  /// Find deprecated API usage
  Future<List<DeprecatedApiUsage>> _findDeprecatedUsage() async {
    final deprecatedUsages = <DeprecatedApiUsage>[];
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final lines = await file.readAsLines();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          
          // Look for common deprecated patterns
          if (line.contains('deprecated') || 
              line.contains('@deprecated') ||
              line.contains('will be removed')) {
            deprecatedUsages.add(DeprecatedApiUsage(
              filePath: file.path,
              line: i + 1,
              deprecatedApi: _extractDeprecatedApi(line),
              replacement: _extractReplacement(line),
              message: 'Deprecated API usage found',
            ));
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return deprecatedUsages;
  }

  /// Analyze code style and patterns
  Future<CodeStyleProfile> _analyzeCodeStyle() async {
    final asyncPatterns = <String>[];
    final stateManagement = <String>[];
    final architecturePatterns = <String>[];
    final namingConventions = <String, int>{};
    bool usesNullSafety = false;
    bool usesExtensionMethods = false;
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        
        // Check for patterns
        if (content.contains('async ') || content.contains('await ')) {
          asyncPatterns.add('async/await');
        }
        if (content.contains('FutureBuilder') || content.contains('StreamBuilder')) {
          stateManagement.add('Flutter Builders');
        }
        if (content.contains('extension ')) {
          usesExtensionMethods = true;
        }
        if (content.contains('String?') || content.contains('int?')) {
          usesNullSafety = true;
        }
        
        // Analyze naming patterns
        final classMatches = RegExp(r'class\s+(\w+)').allMatches(content);
        for (final match in classMatches) {
          final className = match.group(1);
          if (className != null) {
            namingConventions['classes'] = (namingConventions['classes'] ?? 0) + 1;
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return CodeStyleProfile(
      asyncPatterns: asyncPatterns,
      stateManagement: stateManagement,
      architecturePatterns: architecturePatterns,
      namingConventions: namingConventions,
      usesNullSafety: usesNullSafety,
      usesExtensionMethods: usesExtensionMethods,
    );
  }

  /// Analyze type system usage
  Future<TypeSystemInfo> _analyzeTypeSystem() async {
    final customTypes = <String>[];
    final genericTypes = <String>[];
    final extensionMethods = <String>[];
    final typeAliases = <String, String>{};
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        
        // Find custom types
        final classMatches = RegExp(r'class\s+(\w+)').allMatches(content);
        for (final match in classMatches) {
          final className = match.group(1);
          if (className != null && !_isDartCoreType(className)) {
            customTypes.add(className);
          }
        }
        
        // Find generic types
        final genericMatches = RegExp(r'(\w+)<[^>]+>').allMatches(content);
        for (final match in genericMatches) {
          final typeName = match.group(1);
          if (typeName != null) {
            genericTypes.add(typeName);
          }
        }
        
        // Find extension methods
        final extensionMatches = RegExp(r'extension\s+(\w+)\s+on\s+(\w+)').allMatches(content);
        for (final match in extensionMatches) {
          final extensionName = match.group(1);
          if (extensionName != null) {
            extensionMethods.add(extensionName);
          }
        }
        
        // Find type aliases
        final typedefMatches = RegExp(r'typedef\s+(\w+)\s*=\s*(\w+)').allMatches(content);
        for (final match in typedefMatches) {
          final aliasName = match.group(1);
          final originalType = match.group(2);
          if (aliasName != null && originalType != null) {
            typeAliases[aliasName] = originalType;
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return TypeSystemInfo(
      customTypes: customTypes,
      genericTypes: genericTypes,
      extensionMethods: extensionMethods,
      typeAliases: typeAliases,
    );
  }

  /// Analyze common error patterns
  Future<List<ErrorPattern>> _analyzeErrorPatterns() async {
    final patterns = <ErrorPattern>[];
    
    // Common error patterns to look for
    patterns.add(ErrorPattern(
      pattern: 'Null check operator',
      description: 'Using null check operator (!) on potentially nullable types',
      examples: ['variable!.method()', 'list![index]'],
      frequency: 0,
      commonFix: 'Use proper null safety or null-aware operators',
    ));
    
    patterns.add(ErrorPattern(
      pattern: 'Missing await',
      description: 'Forgetting to await Future operations',
      examples: ['Future<String> result = fetchData();', 'return asyncOperation();'],
      frequency: 0,
      commonFix: 'Add await before Future operations',
    ));
    
    patterns.add(ErrorPattern(
      pattern: 'Unused imports',
      description: 'Importing packages that are not used',
      examples: ["import 'dart:io';", "import 'package:http/http.dart';"],
      frequency: 0,
      commonFix: 'Remove unused imports',
    ));
    
    return patterns;
  }

  /// Helper methods
  Stream<File> _findDartFiles() async* {
    final dir = Directory(projectPath);
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (!entity.path.contains('.dart_tool') && 
            !entity.path.contains('build')) {
          yield entity;
        }
      }
    }
  }

  String? _extractClassName(String filePath) {
    final fileName = filePath.split('/').last;
    return fileName.replaceAll('.dart', '');
  }

  List<String> _extractMethods(String content) {
    final methods = <String>[];
    final methodMatches = RegExp(r'\s*(\w+)\s*\([^)]*\)\s*{').allMatches(content);
    for (final match in methodMatches) {
      final methodName = match.group(1);
      if (methodName != null && methodName != 'class' && methodName != 'void') {
        methods.add(methodName);
      }
    }
    return methods;
  }

  List<String> _extractProperties(String content) {
    final properties = <String>[];
    final propertyMatches = RegExp(r'\s*(\w+)\s*:').allMatches(content);
    for (final match in propertyMatches) {
      final propertyName = match.group(1);
      if (propertyName != null) {
        properties.add(propertyName);
      }
    }
    return properties;
  }

  List<String> _extractConstructors(String content) {
    final constructors = <String>[];
    final constructorMatches = RegExp(r'\s*(\w*)\s*\([^)]*\)\s*{').allMatches(content);
    for (final match in constructorMatches) {
      final constructorName = match.group(1);
      if (constructorName != null) {
        constructors.add(constructorName.isEmpty ? 'default' : constructorName);
      }
    }
    return constructors;
  }

  String? _extractSuperClass(String content) {
    final match = RegExp(r'class\s+\w+\s+extends\s+(\w+)').firstMatch(content);
    return match?.group(1);
  }

  List<String> _extractInterfaces(String content) {
    final interfaces = <String>[];
    final matches = RegExp(r'implements\s+([^{]+)').allMatches(content);
    for (final match in matches) {
      final interfaceList = match.group(1)?.split(',') ?? [];
      for (final interface in interfaceList) {
        interfaces.add(interface.trim());
      }
    }
    return interfaces;
  }

  String _extractDeprecatedApi(String line) {
    final match = RegExp(r'@deprecated\s*([^(]*)').firstMatch(line);
    return match?.group(1)?.trim() ?? 'Unknown deprecated API';
  }

  String? _extractReplacement(String line) {
    final match = RegExp(r'use\s+(\w+)\s+instead').firstMatch(line);
    return match?.group(1);
  }

  bool _isDartCoreType(String typeName) {
    final coreTypes = {
      'String', 'int', 'double', 'bool', 'num', 'dynamic', 'Object',
      'List', 'Map', 'Set', 'Iterable', 'Future', 'Stream',
      'DateTime', 'Duration', 'Uri', 'File', 'Directory'
    };
    return coreTypes.contains(typeName);
  }
}
