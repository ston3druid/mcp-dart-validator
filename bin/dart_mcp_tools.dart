#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/validation/simple_validator.dart';

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

  switch (command) {
    case 'validate':
      await _validateProject(projectPath);
      break;
    case 'analyze':
      await _analyzeProject(projectPath);
      break;
    default:
      print('❌ Unknown command: $command');
      _showUsage();
  }
}

/// Validate project using dart analyze
Future<void> _validateProject(String projectPath) async {
  print('🔍 Validating project at: $projectPath');
  print('⏳ Running dart analyze...');
  
  final validator = SimpleValidator(projectPath: projectPath);
  final result = await validator.validate();
  
  print('\n📊 Validation Results:');
  print('   Status: ${result.success ? "✅ Success" : "❌ Issues Found"}');
  print('   Message: ${result.message}');
  
  if (result.issues.isNotEmpty) {
    print('\n🔍 Issues Found:');
    for (final issue in result.issues.take(20)) {
      final location = issue.line != null ? ' (${issue.line}:${issue.column ?? 0})' : '';
      print('   • ${issue.type}: ${issue.filePath}$location - ${issue.message}');
    }
    
    if (result.issues.length > 20) {
      print('   ... and ${result.issues.length - 20} more issues');
    }
  }
  
  if (!result.success) {
    exit(1);
  }
}

/// Analyze project with detailed output
Future<void> _analyzeProject(String projectPath) async {
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
🚀 Dart Validation MCP Tools - Simplified CLI

USAGE:
  dart run bin/dart_mcp_tools.dart <command> [options]

COMMANDS:
  validate    Validate project using dart analyze
  analyze     Run detailed dart analyze with verbose output

OPTIONS:
  --path <path>    Specify project path (default: current directory)
  --help, -h       Show this help message

EXAMPLES:
  dart run bin/dart_mcp_tools.dart validate
  dart run bin/dart_mcp_tools.dart validate --path /path/to/project
  dart run bin/dart_mcp_tools.dart analyze
  dart run bin/dart_mcp_tools.dart analyze --path /path/to/project

This simplified version uses dart analyze instead of custom validation logic.
''');
}
