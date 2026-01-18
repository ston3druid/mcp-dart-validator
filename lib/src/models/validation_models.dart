/// Models for validation results and reporting
library models;

/// Represents a validation issue found in code
class ValidationIssue {
  final String filePath;
  final String message;
  final String type; // 'error', 'warning', 'info'
  final int? line;
  final int? column;
  final String? rule;

  const ValidationIssue({
    required this.filePath,
    required this.message,
    required this.type,
    this.line,
    this.column,
    this.rule,
  });

  @override
  String toString() {
    final location = line != null ? ' (${line ?? 0}:${column ?? 0})' : '';
    return '$type: $filePath$location - $message';
  }
}

/// Package information from pub.dev
class PackageInfo {
  final String name;
  final String? latestVersion;
  final String? description;
  final bool isValid;
  final String? error;

  const PackageInfo({
    required this.name,
    this.latestVersion,
    this.description,
    required this.isValid,
    this.error,
  });
}

/// Flutter API documentation information
class FlutterApiInfo {
  final String className;
  final bool exists;
  final String? documentationUrl;
  final List<String> constructors;
  final List<String> methods;

  const FlutterApiInfo({
    required this.className,
    required this.exists,
    this.documentationUrl,
    this.constructors = const [],
    this.methods = const [],
  });
}

/// Project validation summary
class ValidationSummary {
  final int totalFiles;
  final int issuesFound;
  final List<ValidationIssue> issues;
  final List<PackageInfo> packages;
  final Duration analysisTime;
  final DateTime timestamp;

  const ValidationSummary({
    required this.totalFiles,
    required this.issuesFound,
    required this.issues,
    required this.packages,
    required this.analysisTime,
    required this.timestamp,
  });

  bool get hasErrors => issues.any((issue) => issue.type == 'error');
  bool get hasWarnings => issues.any((issue) => issue.type == 'warning');

  int get errorCount => issues.where((issue) => issue.type == 'error').length;
  int get warningCount =>
      issues.where((issue) => issue.type == 'warning').length;
  int get infoCount => issues.where((issue) => issue.type == 'info').length;

  @override
  String toString() {
    return '''
Validation Summary - $timestamp
================================
Files analyzed: $totalFiles
Issues found: $issuesFound
Errors: $errorCount
Warnings: $warningCount
Info: $infoCount
Analysis time: ${analysisTime.inMilliseconds}ms
Packages validated: ${packages.length}
================================''';
  }
}

/// Configuration for validation rules
class ValidationConfig {
  final bool strictMode;
  final List<String> excludePaths;
  final List<String> enabledRules;
  final bool checkPackages;
  final bool checkFlutterApi;
  final bool generateReport;

  const ValidationConfig({
    this.strictMode = true,
    this.excludePaths = const [],
    this.enabledRules = const [],
    this.checkPackages = true,
    this.checkFlutterApi = true,
    this.generateReport = false,
  });

  ValidationConfig copyWith({
    bool? strictMode,
    List<String>? excludePaths,
    List<String>? enabledRules,
    bool? checkPackages,
    bool? checkFlutterApi,
    bool? generateReport,
  }) {
    return ValidationConfig(
      strictMode: strictMode ?? this.strictMode,
      excludePaths: excludePaths ?? this.excludePaths,
      enabledRules: enabledRules ?? this.enabledRules,
      checkPackages: checkPackages ?? this.checkPackages,
      checkFlutterApi: checkFlutterApi ?? this.checkFlutterApi,
      generateReport: generateReport ?? this.generateReport,
    );
  }
}
