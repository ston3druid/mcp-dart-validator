#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

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
