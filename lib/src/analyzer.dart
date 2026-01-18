import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/validation_models.dart';

/// Data class for analyzer issue information
class _IssueData {
  final String path;
  final String severity;
  final String message;
  final int? line;
  final int? column;
  final String? code;

  const _IssueData({
    required this.path,
    required this.severity,
    required this.message,
    this.line,
    this.column,
    this.code,
  });
}

/// Enhanced Dart/Flutter analyzer with pub.dev integration
class FlutterAnalyzer {
  static const String _pubDevApi = 'https://pub.dev/api';

  final ValidationConfig config;

  const FlutterAnalyzer({this.config = const ValidationConfig()});

  /// Run comprehensive analysis
  Future<ValidationSummary> analyzeProject(String projectPath) async {
    final stopwatch = Stopwatch()..start();

    final issues = <ValidationIssue>[];
    final packages = <PackageInfo>[];
    int totalFiles = 0;

    // 1. Run Dart analyzer
    final dartIssues = await _runDartAnalyzer(projectPath);
    issues.addAll(dartIssues);

    // 2. Check dependencies if enabled
    if (config.checkPackages) {
      final packageInfo = await _validateDependencies(projectPath);
      packages.addAll(packageInfo);
    }

    // 3. Check Flutter API usage if enabled
    if (config.checkFlutterApi) {
      final flutterIssues = await _checkFlutterApi(projectPath);
      issues.addAll(flutterIssues);
    }

    // 4. Count files
    totalFiles = await _countDartFiles(projectPath);

    stopwatch.stop();

    return ValidationSummary(
      totalFiles: totalFiles,
      issuesFound: issues.length,
      issues: issues,
      packages: packages,
      analysisTime: stopwatch.elapsed,
      timestamp: DateTime.now(),
    );
  }

  /// Run built-in Dart analyzer
  Future<List<ValidationIssue>> _runDartAnalyzer(String projectPath) async {
    try {
      final result = await Process.run('dart', [
        'analyze',
        '--json',
        projectPath,
      ]);
      return _parseAnalyzerOutput(result.stdout as String?, projectPath);
    } catch (e) {
      return [_createAnalyzerErrorIssue(projectPath, e.toString())];
    }
  }

  /// Parse analyzer output and extract issues
  List<ValidationIssue> _parseAnalyzerOutput(
    String? stdout,
    String projectPath,
  ) {
    final issues = <ValidationIssue>[];

    if (stdout?.isNotEmpty != true) return issues;

    final lines = stdout!.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final issue = _tryParseAnalyzerLine(line, projectPath);
      if (issue != null) {
        issues.add(issue);
      }
    }

    return issues;
  }

  /// Try to parse a single analyzer output line
  ValidationIssue? _tryParseAnalyzerLine(String line, String projectPath) {
    try {
      final data = json.decode(line) as Map<String, dynamic>;
      return _parseAnalyzerIssue(data, projectPath);
    } catch (e) {
      // Skip malformed JSON lines
      return null;
    }
  }

  /// Create analyzer error issue
  ValidationIssue _createAnalyzerErrorIssue(String projectPath, String error) {
    return ValidationIssue(
      filePath: projectPath,
      message: 'Failed to run Dart analyzer: $error',
      type: 'error',
    );
  }

  /// Parse Dart analyzer JSON output
  ValidationIssue? _parseAnalyzerIssue(
    Map<String, dynamic> data,
    String projectPath,
  ) {
    final issueData = _extractIssueData(data);

    if (_shouldFilterOutIssue(issueData.path, issueData.code)) {
      return null;
    }

    return ValidationIssue(
      filePath: issueData.path,
      message: issueData.message,
      type: issueData.severity,
      line: issueData.line,
      column: issueData.column,
      rule: issueData.code,
    );
  }

  /// Extract issue data from analyzer JSON
  _IssueData _extractIssueData(Map<String, dynamic> data) {
    return _IssueData(
      path: data['path'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      message: data['message'] as String? ?? '',
      line: data['line'] as int?,
      column: data['column'] as int?,
      code: data['code'] as String?,
    );
  }

  /// Check if issue should be filtered out
  bool _shouldFilterOutIssue(String path, String? code) {
    return _isPathExcluded(path) || _isRuleDisabled(code);
  }

  /// Check if path is excluded from analysis
  bool _isPathExcluded(String path) {
    return config.excludePaths.any((exclude) => path.contains(exclude));
  }

  /// Check if rule is disabled
  bool _isRuleDisabled(String? code) {
    return config.enabledRules.isNotEmpty &&
        !config.enabledRules.contains(code);
  }

  /// Validate project dependencies
  Future<List<PackageInfo>> _validateDependencies(String projectPath) async {
    final packages = <PackageInfo>[];

    try {
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (!await pubspecFile.exists()) {
        return packages;
      }

      final content = await pubspecFile.readAsString();
      final dependencies = _parseDependencies(content);

      for (final dependency in dependencies.entries) {
        final info = await _checkPackageOnPubDev(
          dependency.key,
          dependency.value,
        );
        packages.add(info);
      }
    } catch (e) {
      // Continue with empty packages list on error
    }

    return packages;
  }

  /// Parse dependencies from pubspec.yaml
  Map<String, String> _parseDependencies(String content) {
    final dependencies = <String, String>{};

    // Simple regex for dependency parsing
    final regex = RegExp(r'^\s+([\w_-]+):\s*\^?([\d.]+)', multiLine: true);
    final matches = regex.allMatches(content);

    for (final match in matches) {
      dependencies[match.group(1)!] = match.group(2)!;
    }

    return dependencies;
  }

  /// Check package on pub.dev
  Future<PackageInfo> _checkPackageOnPubDev(
    String packageName,
    String constraint,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_pubDevApi/packages/$packageName'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latest = data['latest'] as Map<String, dynamic>?;

        return PackageInfo(
          name: packageName,
          latestVersion: latest?['version'] as String?,
          description: latest?['description'] as String?,
          isValid: true,
        );
      } else {
        return PackageInfo(
          name: packageName,
          isValid: false,
          error: 'Package not found on pub.dev',
        );
      }
    } catch (e) {
      return PackageInfo(
        name: packageName,
        isValid: false,
        error: 'Failed to check package: $e',
      );
    }
  }

  /// Check Flutter API usage
  Future<List<ValidationIssue>> _checkFlutterApi(String projectPath) async {
    final issues = <ValidationIssue>[];

    try {
      final libDir = Directory('$projectPath/lib');
      if (!await libDir.exists()) {
        return issues;
      }

      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileIssues = await _analyzeFlutterFile(entity);
          issues.addAll(fileIssues);
        }
      }
    } catch (e) {
      issues.add(
        ValidationIssue(
          filePath: projectPath,
          message: 'Failed to check Flutter API: $e',
          type: 'error',
        ),
      );
    }

    return issues;
  }

  /// Analyze individual Flutter file
  Future<List<ValidationIssue>> _analyzeFlutterFile(File file) async {
    final issues = <ValidationIssue>[];
    final content = await file.readAsString();
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check for common issues
      issues.addAll(_checkLineIssues(file.path, i + 1, line));
    }

    return issues;
  }

  /// Check individual line for issues
  List<ValidationIssue> _checkLineIssues(
    String filePath,
    int lineNumber,
    String line,
  ) {
    final issues = <ValidationIssue>[];

    if (_shouldCheckForPrintStatements(filePath, line)) {
      issues.add(_createPrintStatementIssue(filePath, lineNumber));
    }

    if (_hasListWithoutKey(line)) {
      issues.add(_createListKeyIssue(filePath, lineNumber));
    }

    if (_hasNonConstConstructor(line)) {
      issues.add(_createConstConstructorIssue(filePath, lineNumber));
    }

    return issues;
  }

  /// Check if we should validate print statements for this file
  bool _shouldCheckForPrintStatements(String filePath, String line) {
    return !_isExcludedFile(filePath) && line.contains('print(');
  }

  /// Check if file is excluded from print statement validation
  bool _isExcludedFile(String filePath) {
    return filePath.contains('/test/') ||
        filePath.contains('\\test\\') ||
        filePath.endsWith('bin/flutter_mcp_tools.dart') ||
        filePath.contains('project_validator.dart') ||
        filePath.contains('analyzer.dart') ||
        filePath.contains('flutter_docs_checker.dart');
  }

  /// Check if line contains List widget without key
  bool _hasListWithoutKey(String line) {
    return RegExp(r'List<\w+>\s*\[').hasMatch(line) && !line.contains('key:');
  }

  /// Check if line has non-const constructor usage
  bool _hasNonConstConstructor(String line) {
    final constructorPattern = RegExp(r'\b[A-Z][a-zA-Z]*\(');
    return constructorPattern.hasMatch(line) &&
        !line.contains('const ') &&
        !line.contains('new ') &&
        !line.contains('.') &&
        !_isControlFlowStatement(line);
  }

  /// Check if line is a control flow statement
  bool _isControlFlowStatement(String line) {
    return line.contains('print(') ||
        line.contains('if(') ||
        line.contains('for(') ||
        line.contains('while(');
  }

  /// Create print statement validation issue
  ValidationIssue _createPrintStatementIssue(String filePath, int lineNumber) {
    return ValidationIssue(
      filePath: filePath,
      message: 'Use debugPrint instead of print in production code',
      type: 'warning',
      line: lineNumber,
      rule: 'avoid_print',
    );
  }

  /// Create list key validation issue
  ValidationIssue _createListKeyIssue(String filePath, int lineNumber) {
    return ValidationIssue(
      filePath: filePath,
      message: 'List widgets should have keys for proper rebuilding',
      type: 'info',
      line: lineNumber,
      rule: 'use_key_in_widget_constructors',
    );
  }

  /// Create const constructor validation issue
  ValidationIssue _createConstConstructorIssue(
    String filePath,
    int lineNumber,
  ) {
    return ValidationIssue(
      filePath: filePath,
      message: 'Consider using const constructor for better performance',
      type: 'info',
      line: lineNumber,
      rule: 'prefer_const_constructors',
    );
  }

  /// Count Dart files in project
  Future<int> _countDartFiles(String projectPath) async {
    int count = 0;

    try {
      final libDir = Directory('$projectPath/lib');
      if (await libDir.exists()) {
        await for (final entity in libDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            count++;
          }
        }
      }
    } catch (e) {
      // Return 0 on error
    }

    return count;
  }
}
