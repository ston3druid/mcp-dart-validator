#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/validation/simple_validator.dart';
import '../lib/src/models/validation_models.dart';

/// Simplified Dart Validation MCP Tools CLI
/// Uses dart analyze instead of custom validation logic
void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _showUsage();
    return;
  }

  final command = args[0];
  final projectPath = args.contains('--path') 
      ? args[args.indexOf('--path') + 1]
      : Directory.current.path;
  
  // Parse configuration options
  final excludePaths = <String>[];
  var verbose = false;
  var outputFormat = 'text';
  
  for (int i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--exclude':
        if (i + 1 < args.length) {
          excludePaths.add(args[i + 1]);
          i++; // Skip next argument
        }
        break;
      case '--verbose':
        verbose = true;
        break;
      case '--format':
        if (i + 1 < args.length) {
          outputFormat = args[i + 1];
          i++; // Skip next argument
        }
        break;
    }
  }

  switch (command) {
    case 'validate':
      await _validateProject(projectPath, excludePaths, verbose, outputFormat);
      break;
    case 'analyze':
      await _analyzeProject(projectPath, verbose);
      break;
    default:
      print('❌ Unknown command: $command');
      _showUsage();
  }
}

/// Validate project using dart analyze
Future<void> _validateProject(String projectPath, List<String> excludePaths, bool verbose, String outputFormat) async {
  print('🔍 Validating project at: $projectPath');
  if (excludePaths.isNotEmpty) {
    print('🚫 Excluding paths: ${excludePaths.join(', ')}');
  }
  print('⏳ Running dart analyze...');
  
  final validator = SimpleValidator(
    projectPath: projectPath, 
    excludePaths: excludePaths,
    verbose: verbose,
  );
  final result = await validator.validate();
  
  if (outputFormat == 'json') {
    _outputJson(result);
  } else {
    _outputText(result);
  }
  
  if (!result.success) {
    exit(1);
  }
}

/// Output results in text format
void _outputText(ValidationResult result) {
  print('\n📊 Validation Results:');
  print('   Status: ${result.success ? "✅ Success" : "❌ Issues Found"}');
  print('   Files analyzed: ${result.filesAnalyzed}');
  print('   Analysis time: ${result.analysisTime.inMilliseconds}ms');
  print('   Message: ${result.message}');
  
  if (result.issues.isNotEmpty) {
    print('\n🔍 Issues Summary:');
    print('   Errors: ${result.errorCount}');
    print('   Warnings: ${result.warningCount}');
    print('   Info: ${result.infoCount}');
    
    print('\n🔍 Issues Found (showing first 20):');
    for (final issue in result.issues.take(20)) {
      final location = issue.line != null ? ' (${issue.line}:${issue.column ?? 0})' : '';
      final icon = _getIssueIcon(issue.type);
      print('   $icon ${issue.type}: ${issue.filePath}$location - ${issue.message}');
      if (issue.suggestion != null && issue.suggestion!.isNotEmpty) {
        print('     💡 Suggestion: ${issue.suggestion}');
      }
    }
    
    if (result.issues.length > 20) {
      print('   ... and ${result.issues.length - 20} more issues');
    }
  }
}

/// Output results in JSON format
void _outputJson(ValidationResult result) {
  final jsonResult = {
    'success': result.success,
    'filesAnalyzed': result.filesAnalyzed,
    'analysisTimeMs': result.analysisTime.inMilliseconds,
    'message': result.message,
    'summary': {
      'totalIssues': result.issues.length,
      'errors': result.errorCount,
      'warnings': result.warningCount,
      'info': result.infoCount,
    },
    'issues': result.issues.map((issue) => {
      'type': issue.type,
      'filePath': issue.filePath,
      'line': issue.line,
      'column': issue.column,
      'message': issue.message,
      'rule': issue.rule,
      'suggestion': issue.suggestion,
    }).toList(),
  };
  
  print(jsonResult);
}

String _getIssueIcon(String type) {
  switch (type.toLowerCase()) {
    case 'error':
      return '🚨';
    case 'warning':
      return '⚠️';
    case 'info':
      return 'ℹ️';
    default:
      return '📝';
  }
}

/// Analyze project with detailed output
Future<void> _analyzeProject(String projectPath, bool verbose) async {
  print('🔬 Analyzing project at: $projectPath');
  print('⏳ Running detailed analysis...');
  
  // Run dart analyze with verbose output
  final result = await Process.run('dart', ['analyze', '--verbose'], 
      workingDirectory: projectPath);
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors:');
    print(result.stderr);
  }
  
  if (result.exitCode != 0) {
    print('\n❌ Analysis failed with exit code ${result.exitCode}');
    exit(1);
  } else {
    print('\n✅ Analysis completed successfully');
  }
}

/// Show usage information
void _showUsage() {
  print('''
🚀 Dart Validation MCP Tools - Enhanced CLI

USAGE:
  dart run bin/dart_mcp_tools.dart <command> [options]

COMMANDS:
  validate    Validate project using dart analyze
  analyze     Run detailed dart analyze with verbose output

OPTIONS:
  --path <path>           Specify project path (default: current directory)
  --exclude <path>        Exclude path from analysis (can be used multiple times)
  --verbose               Show detailed progress and error information
  --format <format>       Output format: text (default) or json
  --help, -h              Show this help message

EXAMPLES:
  dart run bin/dart_mcp_tools.dart validate
  dart run bin/dart_mcp_tools.dart validate --path /path/to/project
  dart run bin/dart_mcp_tools.dart validate --exclude test --exclude build
  dart run bin/dart_mcp_tools.dart validate --format json
  dart run bin/dart_mcp_tools.dart validate --verbose
  dart run bin/dart_mcp_tools.dart analyze
  dart run bin/dart_mcp_tools.dart analyze --verbose

This enhanced version provides:
- File counting and timing information
- Robust error handling and validation
- Configurable exclude paths
- Multiple output formats (text/json)
- Progress indicators for large projects
- Better error messages and suggestions
''');
}
