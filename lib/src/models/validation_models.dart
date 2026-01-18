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
  final String? suggestion;

  const ValidationIssue({
    required this.filePath,
    required this.message,
    required this.type,
    this.line,
    this.column,
    this.rule,
    this.suggestion,
  });

  @override
  String toString() {
    final location = line != null ? ' (${line ?? 0}:${column ?? 0})' : '';
    return '$type: $filePath$location - $message';
  }
}

/// Simple validation result
class ValidationResult {
  final bool success;
  final List<ValidationIssue> issues;
  final String message;
  final int filesAnalyzed;
  final Duration analysisTime;

  ValidationResult({
    required this.success,
    required this.issues,
    required this.message,
    this.filesAnalyzed = 0,
    this.analysisTime = Duration.zero,
  });

  int get errorCount => issues.where((issue) => issue.type == 'error').length;
  int get warningCount => issues.where((issue) => issue.type == 'warning').length;
  int get infoCount => issues.where((issue) => issue.type == 'info').length;
}
