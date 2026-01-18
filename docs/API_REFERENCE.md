# Dart Validation MCP - API Reference

## 📖 Overview

This document provides a comprehensive reference for all public APIs in Dart Validation MCP.

## 🚀 Quick Start

```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

// Simple validation
final validator = SimpleValidator(projectPath: '.');
final result = await validator.validate();

print('Files analyzed: ${result.filesAnalyzed}');
print('Issues found: ${result.issues.length}');
```

## 📋 Core Classes

### SimpleValidator

Main entry point for Dart project validation using `dart analyze`.

#### Constructor

```dart
SimpleValidator({
  required String projectPath,
  List<String> excludePaths = const [],
  bool verbose = false,
})
```

**Parameters:**
- `projectPath` (String, required): Path to the project root directory
- `excludePaths` (List<String>, optional): Paths to exclude from analysis
- `verbose` (bool, optional): Enable detailed progress output

**Example:**
```dart
final validator = SimpleValidator(
  projectPath: '/my/dart_project',
  excludePaths: ['test', 'build', '.dart_tool'],
  verbose: true,
);
```

#### Methods

##### `validate()`

Runs dart analyze and returns validation results.

**Returns:** `Future<ValidationResult>`

**Example:**
```dart
final result = await validator.validate();

if (result.success) {
  print('✅ Validation passed!');
} else {
  print('❌ Found ${result.issues.length} issues');
  for (final issue in result.issues) {
    print('  ${issue.type}: ${issue.message}');
  }
}
```

### ValidationResult

Contains the results of a validation operation.

#### Properties

- `success` (bool): Whether validation passed without issues
- `issues` (List<ValidationIssue>): List of found issues
- `message` (String): Summary message
- `filesAnalyzed` (int): Number of Dart files analyzed
- `analysisTime` (Duration): Time taken for analysis

#### Computed Properties

- `errorCount` (int): Number of error-level issues
- `warningCount` (int): Number of warning-level issues
- `infoCount` (int): Number of info-level issues

**Example:**
```dart
final result = await validator.validate();

print('Status: ${result.success ? "PASS" : "FAIL"}');
print('Files: ${result.filesAnalyzed}');
print('Time: ${result.analysisTime.inMilliseconds}ms');
print('Errors: ${result.errorCount}');
print('Warnings: ${result.warningCount}');
print('Info: ${result.infoCount}');
```

### ValidationIssue

Represents a single validation issue found by dart analyze.

#### Constructor

```dart
const ValidationIssue({
  required String filePath,
  required String message,
  required String type,
  int? line,
  int? column,
  String? rule,
  String? suggestion,
})
```

**Parameters:**
- `filePath` (String, required): Path to the file with the issue
- `message` (String, required): Issue description
- `type` (String, required): Issue type ('error', 'warning', 'info')
- `line` (int?, optional): Line number where issue occurs
- `column` (int?, optional): Column number where issue occurs
- `rule` (String?, optional): Lint rule that triggered the issue
- `suggestion` (String?, optional): Suggested fix for the issue

#### Properties

- `filePath` (String): File path containing the issue
- `message` (String): Description of the issue
- `type` (String): Issue severity level
- `line` (int?): Line number (null if not applicable)
- `column` (int?): Column number (null if not applicable)
- `rule` (String?): Lint rule identifier
- `suggestion` (String?): Suggested fix from dart analyze

#### Methods

##### `toString()`

Returns a formatted string representation of the issue.

**Returns:** `String`

**Example:**
```dart
final issue = ValidationIssue(
  filePath: 'lib/main.dart',
  message: 'Unused variable',
  type: 'warning',
  line: 15,
  column: 10,
);

print(issue.toString()); // warning: lib/main.dart (15:10) - Unused variable
```

## 🔧 CLI Interface

### Main Commands

#### `validate`

Validates a Dart project using dart analyze.

```bash
dart run bin/dart_mcp_tools.dart validate [options]
```

**Options:**
- `--path <path>`: Specify project path (default: current directory)
- `--exclude <path>`: Exclude path from analysis (can be used multiple times)
- `--verbose`: Show detailed progress and error information
- `--format <format>`: Output format: text (default) or json
- `--help, -h`: Show help message

**Examples:**
```bash
# Basic validation
dart run bin/dart_mcp_tools.dart validate

# With exclusions
dart run bin/dart_mcp_tools.dart validate --exclude test --exclude build

# Verbose output
dart run bin/dart_mcp_tools.dart validate --verbose

# JSON format
dart run bin/dart_mcp_tools.dart validate --format json

# Custom path
dart run bin/dart_mcp_tools.dart validate --path /path/to/project
```

#### `analyze`

Runs detailed dart analyze with verbose output.

```bash
dart run bin/dart_mcp_tools.dart analyze [options]
```

**Options:**
- `--path <path>`: Specify project path (default: current directory)
- `--verbose`: Show detailed progress and error information
- `--help, -h`: Show help message

**Examples:**
```bash
# Detailed analysis
dart run bin/dart_mcp_tools.dart analyze

# Verbose analysis
dart run bin/dart_mcp_tools.dart analyze --verbose

# Custom path
dart run bin/dart_mcp_tools.dart analyze --path /path/to/project
```

## 📊 Output Formats

### Text Format (Default)

Human-readable output with emojis and structured formatting.

```
🔍 Validating project at: /path/to/project
⏳ Running dart analyze...

📊 Validation Results:
   Status: ✅ Success
   Files analyzed: 4
   Analysis time: 754ms
   Message: No issues found
```

### JSON Format

Machine-readable JSON output for CI/CD integration.

```json
{
  "success": true,
  "filesAnalyzed": 4,
  "analysisTimeMs": 689,
  "message": "No issues found",
  "summary": {
    "totalIssues": 0,
    "errors": 0,
    "warnings": 0,
    "info": 0
  },
  "issues": []
}
```

## 🛡️ Error Handling

### Validation Errors

The tool handles various error conditions gracefully:

- **Dart SDK not found**: Clear error message with installation guidance
- **Not a Dart project**: Detects missing pubspec.yaml
- **Malformed JSON**: Skips invalid lines and reports count
- **Process failures**: Comprehensive error reporting

### Error Types

- `ValidationException`: Base exception for validation errors
- `DartSdkNotFoundException`: Dart SDK not available
- `NotADartProjectException`: Project lacks pubspec.yaml
- `AnalysisFailedException`: dart analyze process failed

## 🎯 Usage Patterns

### Basic Validation

```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

Future<bool> validateProject(String path) async {
  final validator = SimpleValidator(projectPath: path);
  final result = await validator.validate();
  
  return result.success;
}
```

### CI/CD Integration

```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

Future<void> ciValidation() async {
  final validator = SimpleValidator(
    projectPath: '.',
    excludePaths: ['test', 'build'],
    verbose: true,
  );
  
  final result = await validator.validate();
  
  if (!result.success) {
    print('❌ CI validation failed:');
    for (final issue in result.issues) {
      if (issue.type == 'error') {
        print('  ${issue.message}');
      }
    }
    exit(1);
  }
  
  print('✅ CI validation passed');
}
```

### Custom Reporting

```dart
import 'package:dart_validation_mcp/flutter_mcp_tools.dart';

Future<Map<String, dynamic>> generateReport(String path) async {
  final validator = SimpleValidator(projectPath: path);
  final result = await validator.validate();
  
  return {
    'timestamp': DateTime.now().toIso8601String(),
    'projectPath': path,
    'success': result.success,
    'filesAnalyzed': result.filesAnalyzed,
    'analysisTimeMs': result.analysisTime.inMilliseconds,
    'issues': result.issues.map((issue) => {
      'type': issue.type,
      'file': issue.filePath,
      'line': issue.line,
      'message': issue.message,
    }).toList(),
  };
}
```

## 🔍 Advanced Features

### Path Exclusions

Exclude specific directories or files from analysis:

```dart
final validator = SimpleValidator(
  projectPath: '.',
  excludePaths: [
    'test',           // Exclude test directory
    'build',          // Exclude build directory
    '.dart_tool',     // Exclude Dart tool cache
    'generated',      // Exclude generated files
  ],
);
```

### Verbose Mode

Enable detailed progress and error information:

```dart
final validator = SimpleValidator(
  projectPath: '.',
  verbose: true,  // Shows file counting, parsing errors, etc.
);
```

### Custom Error Handling

```dart
try {
  final result = await validator.validate();
  // Process results...
} catch (e) {
  if (e is DartSdkNotFoundException) {
    print('Please install Dart SDK: https://dart.dev/get-dart');
  } else if (e is NotADartProjectException) {
    print('Not a valid Dart project (pubspec.yaml not found)');
  } else {
    print('Unexpected error: $e');
  }
}
```

## 📝 Library Exports

The main library exports the following classes:

```dart
// Main library export
library flutter_mcp_tools;

// Simple validation
export 'src/validation/simple_validator.dart';

// Models and utilities
export 'src/models/validation_models.dart';
```

## 🚀 Performance Considerations

- **File Counting**: Uses optimized `Directory.list` for cross-platform compatibility
- **Memory Usage**: Streams JSON output to minimize memory footprint
- **Error Handling**: Graceful degradation for malformed analyzer output
- **Caching**: Relies on dart analyze's built-in caching mechanisms

## 📚 Examples

See the main [README.md](README.md) for more comprehensive usage examples and integration patterns.
