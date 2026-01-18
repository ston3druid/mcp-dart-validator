import 'dart:io';
import 'dart:convert';
import '../models/validation_models.dart';

/// Simple wrapper around dart analyze for validation
class SimpleValidator {
  final String projectPath;

  SimpleValidator({required this.projectPath});

  /// Run dart analyze and return results
  Future<ValidationResult> validate() async {
    try {
      final result = await Process.run('dart', ['analyze', '--format=json'], 
          workingDirectory: projectPath);
      
      if (result.exitCode == 0) {
        return ValidationResult(
          success: true,
          issues: [],
          message: 'No issues found',
        );
      }

      final output = result.stdout as String;
      final issues = <ValidationIssue>[];
      
      // Parse dart analyze output
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          final issue = ValidationIssue(
            filePath: data['location']['file'] as String? ?? 'unknown',
            message: data['message'] as String? ?? 'unknown',
            type: _mapSeverity(data['severity'] as String? ?? 'info'),
            line: data['location']['line'] as int?,
            column: data['location']['column'] as int?,
            rule: data['code'] as String?,
            suggestion: null, // dart analyze doesn't provide suggestions
          );
          issues.add(issue);
        } catch (e) {
          // Skip malformed lines
        }
      }

      return ValidationResult(
        success: false,
        issues: issues,
        message: 'Found ${issues.length} issues',
      );
    } catch (e) {
      return ValidationResult(
        success: false,
        issues: [],
        message: 'Failed to run dart analyze: $e',
      );
    }
  }

  String _mapSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      default:
        return 'info';
    }
  }
}

/// Simple validation result
class ValidationResult {
  final bool success;
  final List<ValidationIssue> issues;
  final String message;

  ValidationResult({
    required this.success,
    required this.issues,
    required this.message,
  });
}
