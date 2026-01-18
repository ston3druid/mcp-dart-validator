#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import '../lib/src/context/project_analyzer.dart';
import '../lib/src/context/error_context_provider.dart';
import '../lib/src/context/smart_suggester.dart';

/// AI-Friendly MCP Server for Dart Validation
/// 
/// This MCP server is designed to be extremely easy for AI assistants to use:
/// - Self-documenting tools with clear descriptions
/// - Smart defaults and auto-detection
/// - Helpful error messages and suggestions
/// - Context-aware responses
/// 
/// Available Tools:
/// 1. validate_dart_project - Validate Dart code with smart defaults
/// 2. analyze_project_context - Understand project structure and dependencies
/// 3. get_error_context - Get context for specific errors
/// 4. get_suggestions - Get smart code suggestions
/// 5. help - Get help and available tools
void main() async {
  print('🤖 Dart Validation MCP Server Started - Ready for AI assistance!');
  
  // Simple MCP protocol handling over stdin/stdout
  await for (final line in stdin.transform(utf8.decoder)) {
    Map<String, dynamic>? data;
    
    try {
      data = json.decode(line) as Map<String, dynamic>;
      
      if (data['method'] == 'tools/call') {
        final params = data['params'] as Map<String, dynamic>;
        final toolName = params['name'] as String;
        
        // Route to appropriate tool handler
        final response = await _handleToolCall(toolName, params, data['id']);
        print(json.encode(response));
        
      } else if (data['method'] == 'initialize') {
        // Enhanced initialization with tool discovery
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
              'description': 'AI-friendly Dart validation and context analysis',
              'author': 'AI Assistant Optimized',
            },
          }
        };
        print(json.encode(response));
        
      } else if (data['method'] == 'tools/list') {
        // Return list of available tools with descriptions
        final response = {
          'jsonrpc': '2.0',
          'id': data['id'],
          'result': {
            'tools': [
              {
                'name': 'validate_dart_project',
                'description': 'Validate Dart project with smart defaults',
                'parameters': {
                  'project_path': {'type': 'string', 'description': 'Path to Dart project (auto-detected if not provided)', 'default': '.'},
                  'exclude_paths': {'type': 'array', 'description': 'Paths to exclude from analysis', 'default': ['build', '.dart_tool']},
                  'verbose': {'type': 'boolean', 'description': 'Show detailed output', 'default': false},
                  'format': {'type': 'string', 'description': 'Output format: text or json', 'default': 'text'}
                },
                'examples': [
                  {'description': 'Quick validation with defaults', 'arguments': {}},
                  {'description': 'Validate specific project', 'arguments': {'project_path': '/path/to/project'}},
                  {'description': 'Verbose validation', 'arguments': {'verbose': true}}
                ]
              },
              {
                'name': 'analyze_project_context',
                'description': 'Analyze project structure, dependencies, and available APIs',
                'parameters': {
                  'project_path': {'type': 'string', 'description': 'Path to analyze (auto-detected if not provided)', 'default': '.'}
                },
                'examples': [
                  {'description': 'Analyze current project', 'arguments': {}},
                  {'description': 'Analyze specific path', 'arguments': {'project_path': '/path/to/project'}}
                ]
              },
              {
                'name': 'get_error_context',
                'description': 'Get context and suggestions for specific errors',
                'parameters': {
                  'error_message': {'type': 'string', 'description': 'Error message to analyze', 'required': true},
                  'file_path': {'type': 'string', 'description': 'File where error occurred'},
                  'line': {'type': 'integer', 'description': 'Line number of error'},
                  'column': {'type': 'integer', 'description': 'Column number of error'}
                },
                'examples': [
                  {'description': 'Get help for null error', 'arguments': {'error_message': 'Null check operator used on null value'}},
                  {'description': 'Get context for file error', 'arguments': {'error_message': 'File not found', 'file_path': 'test.dart', 'line': 10}}
                ]
              },
              {
                'name': 'get_suggestions',
                'description': 'Get smart code suggestions based on context',
                'parameters': {
                  'error_type': {'type': 'string', 'description': 'Type of error (null, async, file, list, http)'},
                  'file_path': {'type': 'string', 'description': 'File where help is needed'},
                  'line': {'type': 'integer', 'description': 'Line number for context'},
                  'code_context': {'type': 'string', 'description': 'Surrounding code for context'},
                  'error_message': {'type': 'string', 'description': 'Specific error message'}
                },
                'examples': [
                  {'description': 'Get null safety suggestions', 'arguments': {'error_type': 'null'}},
                  {'description': 'Get async suggestions', 'arguments': {'error_type': 'async', 'file_path': 'test.dart', 'line': 10}},
                  {'description': 'Get suggestions for specific error', 'arguments': {'error_message': 'undefined method', 'file_path': 'test.dart'}}
                ]
              },
              {
                'name': 'help',
                'description': 'Get help and usage information',
                'parameters': {},
                'examples': [
                  {'description': 'Get general help', 'arguments': {}}
                ]
              }
            ]
          }
        };
        print(json.encode(response));
        
      } else {
        // Handle unknown methods gracefully
        final errorResponse = {
          'jsonrpc': '2.0',
          'id': data['id'],
          'error': {
            'code': -32601,
            'message': 'Method not found: ${data['method']}',
            'data': {
              'available_methods': ['initialize', 'tools/list', 'tools/call'],
              'tip': 'Use tools/list to see available tools'
            }
          }
        };
        print(json.encode(errorResponse));
      }
    } catch (e) {
      // Enhanced error handling with helpful messages
      final errorResponse = {
        'jsonrpc': '2.0',
        'id': data?['id'],
        'error': {
          'code': -32603,
          'message': 'Internal error: $e',
          'data': {
            'tip': 'Check your request format and try again',
            'example': '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "help", "arguments": {}}}'
          }
        }
      };
      print(json.encode(errorResponse));
    }
  }
}

/// Handle tool calls with smart routing and error handling
Future<Map<String, dynamic>> _handleToolCall(String toolName, Map<String, dynamic> params, dynamic id) async {
  try {
    switch (toolName) {
      case 'validate_dart_project':
        return await _validateDartProject(params, id);
      case 'analyze_project_context':
        return await _analyzeProjectContext(params, id);
      case 'get_error_context':
        return await _getErrorContext(params, id);
      case 'get_suggestions':
        return await _getSuggestions(params, id);
      case 'help':
        return await _getHelp(params, id);
      default:
        return {
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32601,
            'message': 'Unknown tool: $toolName',
            'data': {
              'available_tools': ['validate_dart_project', 'analyze_project_context', 'get_error_context', 'get_suggestions', 'help'],
              'tip': 'Use tools/list to see all available tools with descriptions'
            }
          }
        };
    }
  } catch (e) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': -32603,
        'message': 'Error executing $toolName: $e',
        'data': {
          'tool': toolName,
          'tip': 'Check your parameters and try again'
        }
      }
    };
  }
}

/// Enhanced validation with smart defaults and helpful output
Future<Map<String, dynamic>> _validateDartProject(Map<String, dynamic> params, dynamic id) async {
  final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
  
  // Smart defaults
  final projectPath = arguments['project_path']?.toString() ?? Directory.current.path;
  final excludePaths = arguments['exclude_paths'] as List? ?? ['build', '.dart_tool', 'generated'];
  final verbose = arguments['verbose'] as bool? ?? false;
  final format = arguments['format'] as String? ?? 'text';
  
  // Build CLI command with smart defaults
  final args = <String>['run', 'bin/dart_mcp_tools.dart', 'validate'];
  
  args.addAll(['--path', projectPath]);
  
  for (final excludePath in excludePaths) {
    args.addAll(['--exclude', excludePath.toString()]);
  }
  
  if (verbose) args.add('--verbose');
  if (format != 'text') args.addAll(['--format', format]);
  
  // Run validation
  final result = await Process.run('dart', args);
  
  // Enhanced response with helpful information
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'result': {
      'success': result.exitCode == 0,
      'output': result.stdout,
      'error': result.stderr.isNotEmpty ? result.stderr : null,
      'metadata': {
        'project_path': projectPath,
        'exclude_paths': excludePaths,
        'format': format,
        'command': 'dart ${args.join(' ')}'
      },
      'tip': result.exitCode != 0 ? 'Check the error output above for details' : 'Validation completed successfully!'
    }
  };
  
  return response;
}

/// Enhanced project context analysis
Future<Map<String, dynamic>> _analyzeProjectContext(Map<String, dynamic> params, dynamic id) async {
  final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
  final projectPath = arguments['project_path']?.toString() ?? Directory.current.path;
  
  try {
    final analyzer = ProjectAnalyzer(projectPath: projectPath);
    final context = await analyzer.analyzeProjectContext();
    
    // Enhanced response with actionable insights
    final response = {
      'jsonrpc': '2.0',
      'id': id,
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
        'insights': {
          'complexity': context.classes.length > 10 ? 'Large project with many classes' : 'Small to medium project',
          'modern_dart': context.codeStyle.usesNullSafety ? 'Uses modern Dart features' : 'Consider migrating to null safety',
          'dependencies': context.dependencies.length > 5 ? 'Many dependencies - review necessity' : 'Lightweight dependencies',
          'deprecated_usage': context.deprecatedApis.length > 0 ? 'Found deprecated APIs - consider updating' : 'No deprecated APIs found'
        },
        'tip': 'Use this context to make informed decisions about code changes and dependencies'
      }
    };
    
    return response;
  } catch (e) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'success': false,
        'error': 'Failed to analyze project context: $e',
        'tip': 'Ensure the project path is valid and contains Dart files'
      }
    };
  }
}

/// Enhanced error context with actionable suggestions
Future<Map<String, dynamic>> _getErrorContext(Map<String, dynamic> params, dynamic id) async {
  final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
  
  final errorMessage = arguments['error_message'] as String? ?? '';
  final filePath = arguments['file_path'] as String? ?? '';
  final line = arguments['line'] as int?;
  final column = arguments['column'] as int?;
  
  if (errorMessage.isEmpty) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': -32602,
        'message': 'error_message parameter is required',
        'data': {
          'required_parameter': 'error_message',
          'example': '{"error_message": "Null check operator used on null value"}'
        }
      }
    };
  }
  
  try {
    final errorContextProvider = ErrorContextProvider(projectPath: Directory.current.path);
    final context = await errorContextProvider.getErrorContext(errorMessage, filePath, line, column);
    
    // Enhanced response with actionable advice
    final response = {
      'jsonrpc': '2.0',
      'id': id,
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
        'quick_fixes': _getQuickFixes(errorMessage),
        'tip': 'Try the suggested solutions above, or use get_suggestions for more help'
      }
    };
    
    return response;
  } catch (e) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'success': false,
        'error': 'Failed to get error context: $e',
        'fallback_suggestions': _getQuickFixes(errorMessage)
      }
    };
  }
}

/// Enhanced suggestions with confidence scoring
Future<Map<String, dynamic>> _getSuggestions(Map<String, dynamic> params, dynamic id) async {
  final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
  
  final errorType = arguments['error_type'] as String?;
  final filePath = arguments['file_path'] as String?;
  final line = arguments['line'] as int?;
  final codeContext = arguments['code_context'] as String?;
  final errorMessage = arguments['error_message'] as String?;
  
  try {
    final suggester = SmartSuggester(projectPath: Directory.current.path);
    final suggestions = await suggester.getSuggestions(
      errorType: errorType,
      filePath: filePath,
      line: line,
      codeContext: codeContext,
      errorMessage: errorMessage,
    );
    
    // Enhanced response with prioritized suggestions
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'success': true,
        'suggestions': suggestions.map((s) => {
          'description': s.description,
          'code': s.code,
          'explanation': s.explanation,
          'required_imports': s.requiredImports,
          'related_classes': s.relatedClasses,
          'confidence': s.confidence,
          'priority': _getPriority(s.confidence)
        }).toList(),
        'count': suggestions.length,
        'tip': suggestions.isEmpty ? 'Try providing more context or error details for better suggestions' : 'Start with the highest confidence suggestions'
      }
    };
    
    return response;
  } catch (e) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'success': false,
        'error': 'Failed to get suggestions: $e',
        'fallback_suggestions': _getFallbackSuggestions(errorType ?? errorMessage)
      }
    };
  }
}

/// Comprehensive help system
Future<Map<String, dynamic>> _getHelp(Map<String, dynamic> params, dynamic id) async {
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'result': {
      'success': true,
      'server_info': {
        'name': 'dart-validation-mcp',
        'version': '1.0.0',
        'description': 'AI-friendly Dart validation and context analysis',
        'author': 'AI Assistant Optimized'
      },
      'available_tools': [
        {
          'name': 'validate_dart_project',
          'purpose': 'Validate Dart code with smart defaults',
          'when_to_use': 'Before committing code, during development, CI/CD checks',
          'quick_start': '{"name": "validate_dart_project", "arguments": {}}'
        },
        {
          'name': 'analyze_project_context',
          'purpose': 'Understand project structure and dependencies',
          'when_to_use': 'When starting work on new project, before making architectural decisions',
          'quick_start': '{"name": "analyze_project_context", "arguments": {}}'
        },
        {
          'name': 'get_error_context',
          'purpose': 'Get help for specific errors',
          'when_to_use': 'When encountering compilation or runtime errors',
          'quick_start': '{"name": "get_error_context", "arguments": {"error_message": "Your error here"}}'
        },
        {
          'name': 'get_suggestions',
          'purpose': 'Get smart code suggestions',
          'when_to_use': 'When unsure how to fix an error or improve code',
          'quick_start': '{"name": "get_suggestions", "arguments": {"error_type": "null"}}'
        }
      ],
      'examples': [
        {
          'scenario': 'Quick validation',
          'request': '{"name": "validate_dart_project", "arguments": {}}',
          'description': 'Validate current project with smart defaults'
        },
        {
          'scenario': 'Help with null error',
          'request': '{"name": "get_error_context", "arguments": {"error_message": "Null check operator used on null value"}}',
          'description': 'Get specific help for null safety issues'
        },
        {
          'scenario': 'Get async suggestions',
          'request': '{"name": "get_suggestions", "arguments": {"error_type": "async"}}',
          'description': 'Get suggestions for async/await issues'
        }
      ],
      'tips': [
        'All tools have smart defaults - you can often call them without parameters',
        'Use analyze_project_context first to understand the codebase',
        'Error context works best with the exact error message',
        'Suggestions are confidence-scored - start with high confidence ones'
      ],
      'tip': 'This MCP server is designed to be AI-friendly - ask for help anytime!'
    }
  };
  
  return response;
}

/// Helper methods for enhanced responses

List<Map<String, String>> _getQuickFixes(String errorMessage) {
  final fixes = <Map<String, String>>[];
  
  if (errorMessage.toLowerCase().contains('null')) {
    fixes.add({
      'issue': 'Null-related error',
      'fix': 'Add null check or use null-aware operator (?.)',
      'example': 'if (variable != null) { variable.method(); }'
    });
  }
  
  if (errorMessage.toLowerCase().contains('undefined')) {
    fixes.add({
      'issue': 'Undefined variable/method',
      'fix': 'Check spelling and ensure variable is defined',
      'example': 'final variable = value; // Define before use'
    });
  }
  
  if (errorMessage.toLowerCase().contains('async')) {
    fixes.add({
      'issue': 'Async/await issue',
      'fix': 'Add await keyword or make function async',
      'example': 'Future<String> result = await asyncFunction();'
    });
  }
  
  return fixes;
}

List<Map<String, String>> _getFallbackSuggestions(String? errorType) {
  final suggestions = <Map<String, String>>[];
  
  if (errorType?.toLowerCase().contains('null') == true) {
    suggestions.add({
      'suggestion': 'Use null-aware operator',
      'code': 'variable?.method()',
      'confidence': 'high'
    });
  }
  
  suggestions.add({
    'suggestion': 'Check dart analyze output',
    'code': 'dart analyze',
    'confidence': 'medium'
  });
  
  return suggestions;
}

String _getPriority(String confidence) {
  switch (confidence.toLowerCase()) {
    case 'high': return '1';
    case 'medium': return '2';
    case 'low': return '3';
    default: return '2';
  }
}
