import 'dart:io';
import 'dart:convert';
import '../models/validation_models.dart';

/// Simple wrapper around dart analyze for validation
class SimpleValidator {
  final String projectPath;
  final List<String> excludePaths;
  final bool verbose;

  SimpleValidator({
    required this.projectPath, 
    this.excludePaths = const [],
    this.verbose = false,
  });

  /// Check if dart command is available
  Future<bool> _checkDartAvailable() async {
    try {
      final result = await Process.run('dart', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if project is a Dart project
  Future<bool> _isDartProject() async {
    final pubspecFile = File('$projectPath/pubspec.yaml');
    return await pubspecFile.exists();
  }

  /// Count Dart files in project
  Future<int> _countDartFiles() async {
    try {
      // Use Directory.list instead of find command for better cross-platform compatibility
      final dir = Directory(projectPath);
      int count = 0;
      
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Skip common build/cache directories
          if (!entity.path.contains('.dart_tool') && 
              !entity.path.contains('build') &&
              !excludePaths.any((exclude) => entity.path.contains(exclude))) {
            count++;
          }
        }
      }
      
      return count;
    } catch (e) {
      if (verbose) {
        print('⚠️  Error counting Dart files: $e');
      }
      return 0;
    }
  }

  /// Run dart analyze and return results
  Future<ValidationResult> validate() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Pre-flight checks
      if (!await _checkDartAvailable()) {
        return ValidationResult(
          success: false,
          issues: [],
          message: 'Dart SDK not found. Please install Dart SDK.',
          analysisTime: stopwatch.elapsed,
        );
      }

      if (!await _isDartProject()) {
        return ValidationResult(
          success: false,
          issues: [],
          message: 'Not a Dart project (pubspec.yaml not found).',
          analysisTime: stopwatch.elapsed,
        );
      }

      final filesAnalyzed = await _countDartFiles();
      
      // Build analyze command with exclusions
      final args = ['analyze', '--format=json'];
      if (excludePaths.isNotEmpty) {
        for (final path in excludePaths) {
          args.addAll(['--exclude', path]);
        }
      }

      if (verbose) {
        print('🔍 Analyzing $filesAnalyzed Dart files...');
      }

      final result = await Process.run('dart', args, 
          workingDirectory: projectPath);
      
      if (result.exitCode == 0) {
        return ValidationResult(
          success: true,
          issues: [],
          message: 'No issues found',
          filesAnalyzed: filesAnalyzed,
          analysisTime: stopwatch.elapsed,
        );
      }

      final output = result.stdout as String;
      final issues = <ValidationIssue>[];
      int malformedLines = 0;
      
      // Parse dart analyze output with better error handling
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          
          // Validate required fields
          if (data['location'] == null || data['message'] == null) {
            malformedLines++;
            continue;
          }

          final location = data['location'] as Map<String, dynamic>?;
          final issue = ValidationIssue(
            filePath: location?['file'] as String? ?? 'unknown',
            message: data['message'] as String? ?? 'unknown',
            type: _mapSeverity(data['severity'] as String? ?? 'info'),
            line: location?['line'] as int?,
            column: location?['column'] as int?,
            rule: data['code'] as String?,
            suggestion: data['correction'] as String?, // dart analyze provides corrections
          );
          issues.add(issue);
        } on FormatException {
          malformedLines++;
          if (verbose) {
            print('⚠️  Malformed JSON line: ${line.substring(0, 50)}...');
          }
        } catch (e) {
          malformedLines++;
          if (verbose) {
            print('⚠️  Error parsing line: $e');
          }
        }
      }

      String message = 'Found ${issues.length} issues';
      if (malformedLines > 0) {
        message += ' (skipped $malformedLines malformed lines)';
      }

      return ValidationResult(
        success: false,
        issues: issues,
        message: message,
        filesAnalyzed: filesAnalyzed,
        analysisTime: stopwatch.elapsed,
      );
    } catch (e) {
      return ValidationResult(
        success: false,
        issues: [],
        message: 'Failed to run dart analyze: $e',
        analysisTime: stopwatch.elapsed,
      );
    } finally {
      stopwatch.stop();
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
