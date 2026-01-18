#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/project_validator.dart';
import '../lib/src/pub_dev_checker.dart';
import '../lib/src/models/validation_models.dart';

/// Command-line interface for Flutter MCP Tools
void main(List<String> args) async {
  if (args.isEmpty) {
    _showUsage();
    return;
  }

  final command = args.first;
  final projectPath = Directory.current.path;
  final validator = ProjectValidator();

  try {
    switch (command) {
      case 'validate':
        await _handleValidation(args, validator, projectPath);
        break;

      case 'check-deps':
        await _handleDependencyCheck(validator, projectPath);
        break;

      case 'docs-check':
        await _handleDocsCheck(validator, projectPath, args.skip(1));
        break;

      case 'health':
        await _handleHealthCheck(validator, projectPath);
        break;

      case 'setup-ci':
        await ProjectValidator.setupCIValidation();
        break;

      case 'version':
        _showVersion();
        break;

      default:
        print('❌ Unknown command: $command');
        _showUsage();
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Handle validation command
Future<void> _handleValidation(
  List<String> args,
  ProjectValidator validator,
  String projectPath,
) async {
  final isQuick = args.contains('--quick');
  final generateReport = args.contains('--report');

  ValidationSummary summary;

  if (isQuick) {
    summary = await validator.quickValidate(projectPath);
  } else {
    summary = await validator.validateProject(projectPath);
  }

  // Print summary
  print(summary.toString());

  // Generate report if requested
  if (generateReport) {
    final reportPath = args.contains('--output')
        ? args[args.indexOf('--output') + 1]
        : 'validation-report.md';

    await validator.generateReport(summary, reportPath);
  }

  // Exit with error code if issues found
  if (summary.hasErrors) {
    exit(1);
  }
}

/// Handle dependency check command
Future<void> _handleDependencyCheck(
  ProjectValidator validator,
  String projectPath,
) async {
  print('📦 Checking dependencies...\n');

  final summary = await validator.validateProject(projectPath);

  // Print package validation results
  print(PubDevChecker.generateDependencyReport(summary.packages));

  // Exit with error code if invalid packages found
  final invalidPackages = summary.packages.where((p) => !p.isValid);
  if (invalidPackages.isNotEmpty) {
    exit(1);
  }
}

/// Handle documentation check command
Future<void> _handleDocsCheck(
  ProjectValidator validator,
  String projectPath,
  Iterable<String> filePaths,
) async {
  if (filePaths.isEmpty) {
    print('❌ No files specified for docs check');
    print('Usage: flutter_mcp_tools docs-check <file1.dart> <file2.dart> ...');
    return;
  }

  print('📚 Checking Flutter documentation usage...\n');

  for (final filePath in filePaths) {
    final issues = await validator.validateFile(filePath);

    if (issues.isNotEmpty) {
      print('📄 $filePath:');
      for (final issue in issues) {
        print('  ${issue.type}: ${issue.message}');
      }
      print('');
    } else {
      print('✅ $filePath: No issues found');
    }
  }
}

/// Handle health check command
Future<void> _handleHealthCheck(
  ProjectValidator validator,
  String projectPath,
) async {
  print('🏥 Checking project health...\n');

  final summary = await validator.validateProject(projectPath);
  final healthReport = validator.generateHealthReport(summary);

  print(healthReport);
}

/// Show usage information
void _showUsage() {
  print('''
Flutter MCP Tools - Comprehensive Flutter project validation

USAGE:
  flutter_mcp_tools <command> [options]

COMMANDS:
  validate           Run comprehensive project validation
  check-deps        Check dependencies against pub.dev
  docs-check         Check Flutter documentation usage
  health             Generate project health report
  setup-ci           Setup CI/CD validation
  version            Show version information

OPTIONS:
  --quick            Run quick validation (analyze + deps only)
  --report           Generate detailed report
  --output <file>    Specify report output file

EXAMPLES:
  flutter_mcp_tools validate
  flutter_mcp_tools validate --quick --report
  flutter_mcp_tools check-deps
  flutter_mcp_tools docs-check lib/main.dart lib/app.dart
  flutter_mcp_tools health
  flutter_mcp_tools setup-ci

For more information, visit: https://github.com/your-org/flutter_mcp_tools
''');
}

/// Show version information
void _showVersion() {
  print('Flutter MCP Tools v1.0.0');
  print('A comprehensive Flutter project validation toolkit');
  print('');
  print('Features:');
  print('  • Enhanced Dart analysis');
  print('  • pub.dev package validation');
  print('  • Flutter API documentation checking');
  print('  • Project health scoring');
  print('  • CI/CD integration');
  print('  • Customizable validation rules');
}
