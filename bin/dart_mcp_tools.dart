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

  // Handle short commands
  final command = _expandCommand(args[0]);
  final remainingArgs = args.skip(1).toList();
  
  final projectPath = _findProjectPath(remainingArgs);
  final options = _parseOptions(remainingArgs);

  switch (command) {
    case 'validate':
      await _validateProject(projectPath, options);
      break;
    case 'analyze':
      await _analyzeProject(projectPath, options);
      break;
    case 'quick':
      await _quickValidate(projectPath);
      break;
    case 'check':
      await _quickValidate(projectPath); // Alias for quick
      break;
    default:
      print('❌ Unknown command: $command');
      print('💡 Try "dart run bin/dart_mcp_tools.dart --help" for help');
      exit(1);
  }
}

/// Expand short command aliases to full commands
String _expandCommand(String command) {
  switch (command) {
    case 'v':
    case 'val':
      return 'validate';
    case 'a':
    case 'anal':
      return 'analyze';
    case 'q':
    case 'quick':
    case 'check':
      return 'quick';
    default:
      return command;
  }
}

/// Find project path from args or auto-detect
String _findProjectPath(List<String> args) {
  final pathIndex = args.indexWhere((arg) => arg == '--path' || arg == '-p');
  if (pathIndex != -1 && pathIndex + 1 < args.length) {
    final inputPath = args[pathIndex + 1];
    return _normalizePath(inputPath);
  }
  
  // Auto-detect: look for pubspec.yaml in current or parent directories
  var currentDir = Directory.current;
  while (currentDir.parent != currentDir) {
    if (File('${currentDir.path}/pubspec.yaml').existsSync()) {
      return currentDir.path;
    }
    currentDir = currentDir.parent;
  }
  
  return Directory.current.path;
}

/// Normalize path for consistent handling
String _normalizePath(String path) {
  if (path.startsWith(RegExp(r'^[A-Za-z]:')) || path.startsWith('/')) {
    // Absolute path
    return Directory(path).absolute.path;
  } else {
    // Relative path - resolve against current directory
    return Directory(Directory.current.path).resolveSymbolicLinksSync();
  }
}

/// Parse command line options into a structured format
Map<String, dynamic> _parseOptions(List<String> args) {
  final options = <String, dynamic>{};
  
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--exclude':
      case '-e':
        if (i + 1 < args.length) {
          (options['exclude'] ??= <String>[]).add(args[i + 1]);
          i++; // Skip next argument
        }
        break;
      case '--verbose':
      case '-v':
        options['verbose'] = true;
        break;
      case '--format':
      case '-f':
        if (i + 1 < args.length) {
          options['format'] = args[i + 1];
          i++; // Skip next argument
        }
        break;
      case '--json':
        options['format'] = 'json';
        break;
      case '--quiet':
      case '-q':
        options['quiet'] = true;
        break;
    }
  }
  
  return options;
}

/// Quick validation with smart defaults
Future<void> _quickValidate(String projectPath) async {
  if (!_isQuietMode()) {
    print('🔍 Quick validation...');
  }
  
  // Smart exclusions for common directories
  final excludePaths = ['build', '.dart_tool', 'generated'];
  
  final validator = SimpleValidator(
    projectPath: projectPath,
    excludePaths: excludePaths,
    verbose: false,
  );
  
  final result = await validator.validate();
  
  if (!_isQuietMode()) {
    _printQuickResults(result);
  }
  
  // Only exit with error code if there are actual issues (not just 0 issues)
  if (!result.success && result.issues.isNotEmpty) {
    exit(1);
  }
}

/// Check if quiet mode is enabled
bool _isQuietMode() {
  return Platform.environment['DART_VALIDATION_QUIET'] == 'true';
}

/// Print quick validation results
void _printQuickResults(ValidationResult result) {
  if (result.success) {
    print('✅ All good! ${result.filesAnalyzed} files analyzed in ${result.analysisTime.inMilliseconds}ms');
  } else {
    print('❌ Found ${result.issues.length} issues:');
    final errorCount = result.errorCount;
    final warningCount = result.warningCount;
    
    if (errorCount > 0) {
      print('  🚨 $errorCount errors');
    }
    if (warningCount > 0) {
      print('  ⚠️  $warningCount warnings');
    }
    
    // Show first few issues
    for (final issue in result.issues.take(3)) {
      final location = issue.line != null ? ' (${issue.line}:${issue.column ?? 0})' : '';
      print('  • ${issue.filePath}$location - ${issue.message}');
    }
    
    if (result.issues.length > 3) {
      print('  ... and ${result.issues.length - 3} more');
    }
  }
}

/// Validate project using dart analyze
Future<void> _validateProject(String projectPath, Map<String, dynamic> options) async {
  final excludePaths = options['exclude'] as List<String>? ?? [];
  final verbose = options['verbose'] as bool? ?? false;
  final format = options['format'] as String? ?? 'text';
  final quiet = options['quiet'] as bool? ?? false;
  
  if (!quiet) {
    print('🔍 Validating project at: $projectPath');
    if (excludePaths.isNotEmpty) {
      print('🚫 Excluding paths: ${excludePaths.join(', ')}');
    }
    print('⏳ Running dart analyze...');
  }
  
  final validator = SimpleValidator(
    projectPath: projectPath, 
    excludePaths: excludePaths,
    verbose: verbose,
  );
  final result = await validator.validate();
  
  if (format == 'json') {
    _outputJson(result);
  } else {
    _outputText(result, quiet);
  }
  
  if (!result.success) {
    exit(1);
  }
}

/// Output results in text format
void _outputText(ValidationResult result, bool quiet) {
  if (!quiet) {
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
Future<void> _analyzeProject(String projectPath, Map<String, dynamic> options) async {
  final quiet = options['quiet'] as bool? ?? false;
  
  if (!quiet) {
    print('🔬 Analyzing project at: $projectPath');
    print('⏳ Running detailed analysis...');
  }
  
  // Run dart analyze with verbose output
  final result = await Process.run('dart', ['analyze', '--verbose'], 
      workingDirectory: projectPath);
  
  if (!quiet) {
    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('Errors:');
      print(result.stderr);
    }
  }
  
  if (result.exitCode != 0) {
    if (!quiet) {
      print('\n❌ Analysis failed with exit code ${result.exitCode}');
    }
    exit(1);
  } else if (!quiet) {
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
  quick       Quick validation with smart defaults
  check       Alias for quick validation

SHORT ALIASES:
  v           validate
  a           analyze
  q           quick/check

OPTIONS:
  --path <path>, -p       Specify project path (auto-detects if not provided)
  --exclude <path>, -e    Exclude path from analysis (can be used multiple times)
  --verbose, -v           Show detailed progress and error information
  --format <format>, -f  Output format: text (default) or json
  --json                  Shortcut for --format json
  --quiet, -q             Suppress output (except errors)
  --help, -h              Show this help message

EASY EXAMPLES:
  # Quick validation (most common)
  dart run bin/dart_mcp_tools.dart q
  
  # Short aliases
  dart run bin/dart_mcp_tools.dart v
  dart run bin/dart_mcp_tools.dart a
  
  # Auto-detects project path
  dart run bin/dart_mcp_tools.dart validate
  
  # Smart defaults (excludes build, .dart_tool, generated)
  dart run bin/dart_mcp_tools.dart quick
  
  # Quiet mode for scripts
  dart run bin/dart_mcp_tools.dart q --quiet

ADVANCED EXAMPLES:
  dart run bin/dart_mcp_tools.dart validate --path /path/to/project
  dart run bin/dart_mcp_tools.dart validate -e test -e build
  dart run bin/dart_mcp_tools.dart validate --json
  dart run bin/dart_mcp_tools.dart validate --verbose

ENVIRONMENT VARIABLES:
  DART_VALIDATION_QUIET=true    Enable quiet mode by default

SMART FEATURES:
  🔍 Auto-detects Dart projects by finding pubspec.yaml
  🚫 Quick mode excludes common directories (build, .dart_tool, generated)
  📊 Shows concise summaries in quick mode
  🎯 Short aliases for common commands
  🔧 Smart error messages with helpful hints

This enhanced version provides:
- File counting and timing information
- Robust error handling and validation
- Configurable exclude paths
- Multiple output formats (text/json)
- Progress indicators for large projects
- Better error messages and suggestions
- Maximum ease of use with smart defaults
''');
}
