#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import '../lib/src/context/project_analyzer.dart';
import '../lib/src/context/error_context_provider.dart';
import '../lib/src/context/smart_suggester.dart';

/// Ultra-simple MCP server that wraps the validation CLI
/// This is the simplest possible approach - just call the existing CLI tool
void main() async {
  // Simple MCP protocol handling over stdin/stdout
  await for (final line in stdin.transform(utf8.decoder)) {
    Map<String, dynamic>? data;
    
    try {
      data = json.decode(line) as Map<String, dynamic>;
      
      if (data['method'] == 'tools/call') {
        final params = data['params'] as Map<String, dynamic>;
        final toolName = params['name'] as String;
        
        if (toolName == 'validate_dart_project') {
          final arguments = params['arguments'] as Map<String, dynamic>;
          
          // Build CLI command
          final args = <String>['run', 'bin/dart_mcp_tools.dart', 'validate'];
          
          if (arguments['project_path'] != null) {
            args.addAll(['--path', arguments['project_path'].toString()]);
          }
          
          if (arguments['exclude_paths'] != null) {
            final excludePaths = arguments['exclude_paths'] as List;
            for (final path in excludePaths) {
              args.addAll(['--exclude', path.toString()]);
            }
          }
          
          if (arguments['verbose'] == true) {
            args.add('--verbose');
          }
          
          final format = arguments['format'] ?? 'text';
          if (format != 'text') {
            args.addAll(['--format', format.toString()]);
          }
          
          // Run the validation
          final result = await Process.run('dart', args);
          
          final response = {
            'jsonrpc': '2.0',
            'id': data['id'],
            'result': {
              'success': result.exitCode == 0,
              'output': result.stdout,
              'error': result.stderr.isNotEmpty ? result.stderr : null,
            }
          };
          
          print(json.encode(response));
        } else if (toolName == 'analyze_project_context') {
          final arguments = params['arguments'] as Map<String, dynamic>;
          final projectPath = arguments['project_path'] ?? Directory.current.path;
          
          final analyzer = ProjectAnalyzer(projectPath: projectPath);
          final context = await analyzer.analyzeProjectContext();
          
          final response = {
            'jsonrpc': '2.0',
            'id': data['id'],
            'result': {
              'success': true,
              'project_path': context.projectPath,
              'dependencies': context.dependencies,
              'class_count': context.classes.length,
              'dart_core_apis': context.dartCoreApis,
              'external_packages': context.externalPackages,
              'deprecated_apis': context.deprecatedApis.length,
              'uses_null_safety': context.codeStyle.usesNullSafety,
              'custom_types': context.typeSystem.customTypes.length,
            }
          };
          
          print(json.encode(response));
        } else if (toolName == 'get_error_context') {
          final arguments = params['arguments'] as Map<String, dynamic>;
          final errorContextProvider = ErrorContextProvider(projectPath: Directory.current.path);
          
          final context = await errorContextProvider.getErrorContext(
            arguments['error_message'] ?? '',
            arguments['file_path'] ?? '',
            arguments['line'] as int?,
            arguments['column'] as int?,
          );
          
          final response = {
            'jsonrpc': '2.0',
            'id': data['id'],
            'result': {
              'success': true,
              'error_message': context.errorMessage,
              'file_path': context.filePath,
              'line': context.line,
              'column': context.column,
              'similar_issues': context.similarIssues,
              'solutions_that_worked': context.solutionsThatWorked,
              'related_classes': context.relatedClasses,
              'available_apis': context.availableApis,
              'import_suggestions': context.importSuggestions,
            }
          };
          
          print(json.encode(response));
        } else if (toolName == 'get_suggestions') {
          final arguments = params['arguments'] as Map<String, dynamic>;
          final suggester = SmartSuggester(projectPath: Directory.current.path);
          
          final suggestions = await suggester.getSuggestions(
            errorType: arguments['error_type'],
            filePath: arguments['file_path'],
            line: arguments['line'] as int?,
            codeContext: arguments['code_context'],
            errorMessage: arguments['error_message'],
          );
          
          final response = {
            'jsonrpc': '2.0',
            'id': data['id'],
            'result': {
              'success': true,
              'suggestions': suggestions.map((s) => {
                'description': s.description,
                'code': s.code,
                'explanation': s.explanation,
                'required_imports': s.requiredImports,
                'related_classes': s.relatedClasses,
                'confidence': s.confidence,
              }).toList(),
            }
          };
          
          print(json.encode(response));
        }
      } else if (data['method'] == 'initialize') {
        // Respond to initialization
        final response = {
          'jsonrpc': '2.0',
          'id': data['id'],
          'result': {
            'capabilities': {
              'tools': {},
            },
            'serverInfo': {
              'name': 'dart-validation-mcp',
              'version': '1.0.0',
            },
          }
        };
        print(json.encode(response));
      }
    } catch (e) {
      final errorResponse = {
        'jsonrpc': '2.0',
        'id': data?['id'],
        'error': {
          'code': -32603,
          'message': 'Internal error: $e',
        }
      };
      print(json.encode(errorResponse));
    }
  }
}
