import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'models/validation_models.dart';

/// Enhanced Flutter documentation API checker
class FlutterDocsChecker {
  static const String _flutterDocsUrl = 'https://api.flutter.dev/flutter';
  static const String _flutterDocsWebUrl = 'https://flutter.dev';

  /// Check if Flutter class/widget exists
  static Future<FlutterApiInfo> checkFlutterClass(String className) async {
    try {
      final response = await http.get(
        Uri.parse('$_flutterDocsUrl/$className/$className-class.html'),
        headers: {'Accept': 'text/html'},
      );

      if (response.statusCode == 200) {
        return FlutterApiInfo(
          className: className,
          exists: true,
          documentationUrl:
              '$_flutterDocsWebUrl/$className/$className-class.html',
        );
      } else {
        return FlutterApiInfo(className: className, exists: false);
      }
    } catch (e) {
      return FlutterApiInfo(className: className, exists: false);
    }
  }

  /// Get Flutter API index
  static Future<Map<String, dynamic>?> getFlutterApiIndex() async {
    try {
      final response = await http.get(
        Uri.parse('$_flutterDocsUrl/index.json'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check widget constructor validity
  static Future<bool> isValidWidgetConstructor(
    String widgetName,
    String constructor,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_flutterDocsUrl/$widgetName/$widgetName.$constructor.html'),
        headers: {'Accept': 'text/html'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Analyze Flutter file for best practices
  static Future<List<ValidationIssue>> analyzeFlutterFile(
    String filePath, {
    bool strictMode = false,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [
        ValidationIssue(
          filePath: filePath,
          message: 'File not found',
          type: 'error',
        ),
      ];
    }

    final content = await file.readAsString();
    return _analyzeFlutterCode(content, filePath, strictMode: strictMode);
  }

  /// Analyze Flutter code for best practices
  static List<ValidationIssue> _analyzeFlutterCode(
    String content,
    String filePath, {
    bool strictMode = false,
  }) {
    final issues = <ValidationIssue>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final line = lines[i];

      // Widget structure checks
      issues.addAll(_checkWidgetStructure(line, filePath, lineNumber));

      // Performance checks
      issues.addAll(_checkPerformance(line, filePath, lineNumber, strictMode));

      // Accessibility checks
      issues.addAll(_checkAccessibility(line, filePath, lineNumber));

      // State management checks
      issues.addAll(_checkStateManagement(line, filePath, lineNumber));
    }

    return issues;
  }

  /// Check widget structure best practices
  static List<ValidationIssue> _checkWidgetStructure(
    String line,
    String filePath,
    int lineNumber,
  ) {
    final issues = <ValidationIssue>[];

    // Check for const constructors
    if (RegExp(r'\w+\(').hasMatch(line) &&
        !line.contains('const ') &&
        !line.contains('new ') &&
        !line.contains('super.')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Consider using const constructor for better performance',
          type: 'info',
          line: lineNumber,
          rule: 'prefer_const_constructors',
        ),
      );
    }

    // Check for keys in lists
    if (RegExp(r'List<\w+>\s*\[').hasMatch(line) && !line.contains('key:')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'List widgets should have keys for proper rebuilding',
          type: 'warning',
          line: lineNumber,
          rule: 'use_key_in_widget_constructors',
        ),
      );
    }

    // Check for build method
    if (RegExp(r'Widget\s+build\(.*context\)').hasMatch(line)) {
      // Build method found - this is good
    }

    return issues;
  }

  /// Check performance best practices
  static List<ValidationIssue> _checkPerformance(
    String line,
    String filePath,
    int lineNumber,
    bool strictMode,
  ) {
    final issues = <ValidationIssue>[];

    // Print statements (allow in validation tools, flag in other library code)
    if (!filePath.contains('/test/') &&
        !filePath.contains('\\test\\') &&
        !filePath.endsWith('bin/flutter_mcp_tools.dart') &&
        !filePath.contains('project_validator.dart') &&
        !filePath.contains('analyzer.dart') &&
        !filePath.contains('flutter_docs_checker.dart') &&
        line.contains('print(')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Use debugPrint instead of print in production code',
          type: 'warning',
          line: lineNumber,
          rule: 'avoid_print',
        ),
      );
    }

    // Check for unnecessary rebuilds
    if (RegExp(r'build\(.*context\)').allMatches(line).length > 1) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Multiple build methods detected - consider refactoring',
          type: 'warning',
          line: lineNumber,
          rule: 'avoid_multiple_build_methods',
        ),
      );
    }

    // Check for const widgets
    final constWidgets = RegExp(r'const\s+\w+\(').allMatches(line);
    if (strictMode && constWidgets.isEmpty && line.contains('Widget(')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Use const widgets when possible for better performance',
          type: 'info',
          line: lineNumber,
          rule: 'prefer_const_widgets',
        ),
      );
    }

    // Check for expensive operations in build
    if (line.contains('build(') &&
        (line.contains('DateTime.now()') || line.contains('Random()'))) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Avoid expensive operations in build method',
          type: 'warning',
          line: lineNumber,
          rule: 'avoid_expensive_build_operations',
        ),
      );
    }

    return issues;
  }

  /// Check accessibility best practices
  static List<ValidationIssue> _checkAccessibility(
    String line,
    String filePath,
    int lineNumber,
  ) {
    final issues = <ValidationIssue>[];

    // Check for semantic labels
    if (RegExp(r'semantics|Semantics').hasMatch(line)) {
      // Semantic widgets found - this is good
    } else if (line.contains('Text(') && !line.contains('semantics')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'Consider adding semantic widgets for better accessibility',
          type: 'info',
          line: lineNumber,
          rule: 'add_semantic_widgets',
        ),
      );
    }

    // Check for tooltip usage
    if (line.contains('Tooltip(')) {
      // Tooltip found - this is good
    } else if (line.contains('IconButton(') && !line.contains('Tooltip')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'IconButton should have a Tooltip for accessibility',
          type: 'info',
          line: lineNumber,
          rule: 'add_tooltips',
        ),
      );
    }

    return issues;
  }

  /// Check state management best practices
  static List<ValidationIssue> _checkStateManagement(
    String line,
    String filePath,
    int lineNumber,
  ) {
    final issues = <ValidationIssue>[];

    // Check for setState usage
    if (RegExp(r'setState\(.*\)').hasMatch(line)) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'setState called - consider state management solution',
          type: 'info',
          line: lineNumber,
          rule: 'track_setstate_usage',
        ),
      );
    }

    // Check for proper dispose
    if (RegExp(r'void\s+dispose\(\)').hasMatch(line)) {
      // Dispose method found - this is good
    } else if (line.contains('State<') && !line.contains('dispose')) {
      issues.add(
        ValidationIssue(
          filePath: filePath,
          message: 'State class should implement dispose method for cleanup',
          type: 'warning',
          line: lineNumber,
          rule: 'implement_dispose',
        ),
      );
    }

    return issues;
  }

  /// Get Flutter version information
  static Future<Map<String, dynamic>?> getFlutterVersionInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/flutter/flutter/releases/latest',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check for deprecated APIs
  static Future<List<ValidationIssue>> checkDeprecatedApis(
    String content,
    String filePath,
  ) async {
    final issues = <ValidationIssue>[];
    final lines = content.split('\n');

    // List of commonly deprecated Flutter APIs
    final deprecatedApis = {
      'Scaffold.of(context).showSnackBar': 'Use ScaffoldMessenger',
      'Theme.of(context).accentColor': 'Use Theme.of(context).colorScheme',
      'RaisedButton': 'Use ElevatedButton',
      'FlatButton': 'Use TextButton',
      'OutlineButton': 'Use OutlinedButton',
    };

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      for (final entry in deprecatedApis.entries) {
        if (line.contains(entry.key)) {
          issues.add(
            ValidationIssue(
              filePath: filePath,
              message:
                  'Deprecated API used: ${entry.key}. Consider: ${entry.value}',
              type: 'warning',
              line: i + 1,
              rule: 'avoid_deprecated_apis',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Generate Flutter best practices report
  static String generateBestPracticesReport(
    List<ValidationIssue> issues,
    String filePath,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('# Flutter Best Practices Report');
    buffer.writeln('File: $filePath');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    final errors = issues.where((i) => i.type == 'error').toList();
    final warnings = issues.where((i) => i.type == 'warning').toList();
    final infos = issues.where((i) => i.type == 'info').toList();

    if (errors.isNotEmpty) {
      buffer.writeln('## Errors (${errors.length})');
      for (final error in errors) {
        buffer.writeln('- **Line ${error.line}**: ${error.message}');
      }
      buffer.writeln('');
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('## Warnings (${warnings.length})');
      for (final warning in warnings) {
        buffer.writeln('- **Line ${warning.line}**: ${warning.message}');
      }
      buffer.writeln('');
    }

    if (infos.isNotEmpty) {
      buffer.writeln('## Suggestions (${infos.length})');
      for (final info in infos) {
        buffer.writeln('- **Line ${info.line}**: ${info.message}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
