# Flutter MCP Tools - API Reference

## 📖 Overview

This document provides a comprehensive reference for all public APIs in Flutter MCP Tools.

## 🚀 Quick Start

```dart
import 'package:flutter_mcp_tools/flutter_mcp_tools.dart';

// Analyze a project
final analysis = await ProjectAnalyzer.analyzeProject('/path/to/project');

// Validate results
final validation = await ProjectValidator.validate(analysis);

// Apply fixes via MCP
final client = MCPRefactorClient();
final fixes = await client.applyFixes('lib/main.dart');
```

## 📋 Core Classes

### ProjectAnalyzer

Main entry point for project analysis and validation.

#### Methods

##### `analyzeProject(String projectPath)`

Analyzes a Flutter/Dart project and returns comprehensive results.

**Parameters:**
- `projectPath` (String): Path to the project root directory

**Returns:** `Future<ProjectAnalysisResult>`

**Example:**
```dart
final result = await ProjectAnalyzer.analyzeProject('/my/flutter_app');
print('Project type: ${result.projectStructure?.isFlutterProject ? 'Flutter' : 'Dart'}');
print('Dart files: ${result.projectStructure?.dartFileCount}');
print('Dependencies: ${result.dependencies.length}');
```

##### `_detectProjectDartVersion(String projectPath)` (Private)

Detects the Dart SDK version from pubspec.yaml.

**Returns:** `Future<Version?>`

##### `_analyzeProjectStructure(String projectPath)` (Private)

Analyzes the project structure and file organization.

**Returns:** `Future<ProjectStructure>`

##### `_analyzeDependencies(String projectPath)` (Private)

Analyzes project dependencies from pubspec.yaml.

**Returns:** `Future<Map<String, DependencyInfo>>`

---

### MCPRefactorClient

Client for MCP-style refactoring operations.

#### Methods

##### `isServerAvailable()`

Checks if MCP server is available.

**Returns:** `Future<bool>`

##### `analyzeForRefactoring(String filePath)`

Analyzes a file for refactoring opportunities.

**Parameters:**
- `filePath` (String): Path to the file to analyze

**Returns:** `Future<Map<String, dynamic>>`

##### `applyFixes(String filePath)`

Applies automated fixes to a file.

**Parameters:**
- `filePath` (String): Path to the file to fix

**Returns:** `Future<List<String>>` - List of applied fixes

##### `formatCode(String content)`

Formats Dart code according to standards.

**Parameters:**
- `content` (String): Dart code to format

**Returns:** `Future<String>` - Formatted code

---

### ProjectValidator

Validates projects against various quality standards.

#### Methods

##### `validate(ProjectAnalysisResult analysis)`

Validates a project analysis result.

**Parameters:**
- `analysis` (ProjectAnalysisResult): Analysis results to validate

**Returns:** `Future<ValidationResult>`

##### `validateStructure(ProjectStructure structure)`

Validates project structure.

**Parameters:**
- `structure` (ProjectStructure): Project structure to validate

**Returns:** `ValidationResult`

---

### PubDevChecker

Validates packages against pub.dev standards.

#### Methods

##### `checkPackage(String packageName)`

Checks a package against pub.dev requirements.

**Parameters:**
- `packageName` (String): Name of the package to check

**Returns:** `Future<PubDevValidationResult>`

##### `validateDependencies(Map<String, DependencyInfo> dependencies)`

Validates project dependencies.

**Parameters:**
- `dependencies` (Map<String, DependencyInfo>): Project dependencies

**Returns:** `DependencyValidationResult`

---

### FlutterDocsChecker

Validates Flutter API documentation.

#### Methods

##### `checkDocumentation(String projectPath)`

Checks Flutter documentation quality.

**Parameters:**
- `projectPath` (String): Path to the project

**Returns:** `Future<DocumentationResult>`

##### `validateApiDocs(String filePath)`

Validates API documentation in a specific file.

**Parameters:**
- `filePath` (String): Path to the Dart file

**Returns:** `ApiDocValidationResult`

---

## 📊 Data Models

### ProjectAnalysisResult

Contains comprehensive analysis results for a project.

#### Properties

```dart
class ProjectAnalysisResult {
  final Version? projectDartVersion;      // Detected Dart SDK version
  final Version? flutterVersion;          // Flutter version
  final ProjectStructure? projectStructure; // Project structure info
  final Map<String, DependencyInfo> dependencies; // Dependencies
  final Map<String, dynamic> recommendedConfig; // Recommended config
  final int? issues;                      // Number of issues found
}
```

#### Constructor

```dart
const ProjectAnalysisResult({
  this.projectDartVersion,
  this.flutterVersion,
  this.projectStructure,
  this.dependencies = const {},
  this.recommendedConfig = const {},
  this.issues = 0,
});
```

---

### ProjectStructure

Information about the project structure and organization.

#### Properties

```dart
class ProjectStructure {
  final bool isFlutterProject;      // True if Flutter project
  final int dartFileCount;         // Number of Dart files
  final int testFileCount;         // Number of test files
  final bool hasTests;              // True if tests exist
  final bool hasGeneratedFiles;     // True if generated files exist
}
```

#### Constructor

```dart
const ProjectStructure({
  this.isFlutterProject = false,
  this.dartFileCount = 0,
  this.testFileCount = 0,
  this.hasTests = false,
  this.hasGeneratedFiles = false,
});
```

---

### DependencyInfo

Information about a project dependency.

#### Properties

```dart
class DependencyInfo {
  final String name;     // Package name
  final String version;  // Package version
}
```

#### Constructor

```dart
const DependencyInfo({
  required this.name,
  required this.version,
});
```

---

### ValidationResult

Result of validation operations.

#### Properties

```dart
class ValidationResult {
  final bool isValid;                    // Overall validation status
  final List<String> errors;            // Error messages
  final List<String> warnings;          // Warning messages
  final List<String> suggestions;        // Improvement suggestions
  final Map<String, dynamic> metrics;    // Validation metrics
}
```

---

## 🔧 Utility Classes

### DartVersionConfig

Handles Dart version detection and configuration.

#### Methods

##### `getRecommendedLintConfig(Version? dartVersion)`

Gets recommended lint configuration for a Dart version.

**Parameters:**
- `dartVersion` (Version?): Dart SDK version

**Returns:** `Map<String, dynamic>`

##### `isVersionSupported(Version version)`

Checks if a Dart version is supported.

**Parameters:**
- `version` (Version): Version to check

**Returns:** `bool`

---

## 📝 Usage Examples

### Complete Project Analysis

```dart
import 'package:flutter_mcp_tools/flutter_mcp_tools.dart';

Future<void> analyzeMyProject() async {
  try {
    // 1. Analyze the project
    final analysis = await ProjectAnalyzer.analyzeProject('/path/to/my/project');
    
    // 2. Display basic info
    print('Project Type: ${analysis.projectStructure?.isFlutterProject ? 'Flutter' : 'Dart'}');
    print('Dart Files: ${analysis.projectStructure?.dartFileCount}');
    print('Dependencies: ${analysis.dependencies.length}');
    
    // 3. Validate the project
    final validation = await ProjectValidator.validate(analysis);
    
    if (validation.isValid) {
      print('✅ Project is valid!');
    } else {
      print('❌ Found ${validation.errors.length} issues:');
      for (final error in validation.errors) {
        print('  - $error');
      }
    }
    
    // 4. Show suggestions
    if (validation.suggestions.isNotEmpty) {
      print('💡 Suggestions:');
      for (final suggestion in validation.suggestions) {
        print('  - $suggestion');
      }
    }
    
  } catch (e) {
    print('Error analyzing project: $e');
  }
}
```

### MCP Refactoring

```dart
Future<void> refactorFile() async {
  final client = MCPRefactorClient();
  
  // Check if server is available
  if (await client.isServerAvailable()) {
    // Analyze file for refactoring opportunities
    final analysis = await client.analyzeForRefactoring('lib/main.dart');
    print('Analysis result: $analysis');
    
    // Apply fixes
    final fixes = await client.applyFixes('lib/main.dart');
    print('Applied ${fixes.length} fixes:');
    for (final fix in fixes) {
      print('  - $fix');
    }
  } else {
    print('MCP server is not available');
  }
}
```

### Dependency Validation

```dart
Future<void> validateDependencies() async {
  final analysis = await ProjectAnalyzer.analyzeProject('/path/to/project');
  final checker = PubDevChecker();
  
  final result = await checker.validateDependencies(analysis.dependencies);
  
  print('Dependencies validation:');
  print('  Valid: ${result.isValid}');
  print('  Outdated: ${result.outdatedPackages.length}');
  print('  Issues: ${result.issues.length}');
  
  if (result.outdatedPackages.isNotEmpty) {
    print('Outdated packages:');
    for (final package in result.outdatedPackages) {
      print('  - ${package.name}: ${package.current} → ${package.latest}');
    }
  }
}
```

## 🚨 Error Handling

### Common Exceptions

- `FileSystemException`: File system related errors
- `FormatException`: Parsing errors (e.g., invalid version format)
- `ArgumentError`: Invalid arguments passed to methods

### Best Practices

```dart
try {
  final analysis = await ProjectAnalyzer.analyzeProject(projectPath);
  // Use analysis results
} on FileSystemException catch (e) {
  // Handle file system errors
  print('File system error: ${e.message}');
} on FormatException catch (e) {
  // Handle parsing errors
  print('Format error: ${e.message}');
} catch (e) {
  // Handle any other errors
  print('Unexpected error: $e');
}
```

## 🔍 Configuration

### Environment Variables

- `FLUTTER_MCP_TOOLS_LOG_LEVEL`: Set logging level (debug, info, warning, error)
- `FLUTTER_MCP_TOOLS_CACHE_DIR`: Custom cache directory
- `FLUTTER_MCP_TOOLS_SERVER_URL`: Custom MCP server URL

### Configuration Files

The tool respects standard Flutter/Dart configuration files:
- `pubspec.yaml`: Project dependencies and metadata
- `analysis_options.yaml`: Linting and analysis rules
- `.dart_tool/`: Build cache and tool data

---

## 📚 Additional Resources

- [Contributing Guide](CONTRIBUTING.md) - How to contribute
- [Architecture Overview](ARCHITECTURE.md) - System design
- [Examples](examples/) - Code examples
- [Flutter Documentation](https://flutter.dev/docs) - Flutter docs
- [Dart Language Guide](https://dart.dev/guides) - Dart docs

---

*This API reference is part of Flutter MCP Tools, licensed under MIT License.*
