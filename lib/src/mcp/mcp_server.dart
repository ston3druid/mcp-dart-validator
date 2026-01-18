import 'dart:io';
import 'dart:convert';
import '../context/project_analyzer.dart';
import '../context/error_context_provider.dart';
import '../context/smart_suggester.dart';
import '../models/context_models.dart';

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
/// 6. self_improve - Analyze and improve the MCP server itself
class DartValidationMcpServer {
  /// Start the MCP server and listen for JSON-RPC requests
  static Future<void> start() async {
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
              'tools': _getToolDefinitions()
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

  /// Get tool definitions for tools/list response
  static List<Map<String, dynamic>> _getToolDefinitions() {
    return [
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
      },
      {
        'name': 'self_improve',
        'description': 'Analyze and improve the MCP server itself',
        'parameters': {
          'analysis_type': {'type': 'string', 'description': 'Type of analysis: deprecated_apis, performance, code_quality, all'},
          'auto_fix': {'type': 'boolean', 'description': 'Automatically apply improvements', 'default': false}
        },
        'examples': [
          {'description': 'Find deprecated APIs in the codebase', 'arguments': {'analysis_type': 'deprecated_apis'}},
          {'description': 'Check code quality issues', 'arguments': {'analysis_type': 'code_quality'}},
          {'description': 'Analyze performance', 'arguments': {'analysis_type': 'performance'}}
        ]
      }
    ];
  }

  /// Handle tool calls with smart routing and error handling
  static Future<Map<String, dynamic>> _handleToolCall(String toolName, Map<String, dynamic> params, dynamic id) async {
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
        case 'self_improve':
          return await _selfImprove(params, id);
        default:
          return {
            'jsonrpc': '2.0',
            'id': id,
            'error': {
              'code': -32601,
              'message': 'Unknown tool: $toolName',
              'data': {
                'available_tools': ['validate_dart_project', 'analyze_project_context', 'get_error_context', 'get_suggestions', 'help', 'self_improve'],
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
  static Future<Map<String, dynamic>> _validateDartProject(Map<String, dynamic> params, dynamic id) async {
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
    
    // Run final dart analyze check to catch any issues
    final validationResult = await _runFinalValidation(projectPath);
    
    // Enhanced response with helpful information
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'success': result.exitCode == 0 && validationResult['has_issues'] == false,
        'output': result.stdout,
        'error': result.stderr.isNotEmpty ? result.stderr : null,
        'metadata': {
          'project_path': projectPath,
          'exclude_paths': excludePaths,
          'format': format,
          'command': 'dart ${args.join(' ')}'
        },
        'final_validation': validationResult,
        'tip': _getValidationTip(result.exitCode, validationResult)
      }
    };
    
    return response;
  }

  /// Get comprehensive validation tip based on results
  static String _getValidationTip(int exitCode, Map<String, dynamic> validationResult) {
    final hasIssues = validationResult['has_issues'] == true;
    final issuesCount = validationResult['issues_count'] ?? 0;
    
    if (exitCode != 0) {
      return '❌ Validation failed - check error output above';
    }
    
    if (hasIssues) {
      return '⚠️ Validation passed but $issuesCount issue(s) found - review final_validation results';
    }
    
    return '✅ Validation completed successfully - no issues detected';
  }

  /// Enhanced project context analysis
  static Future<Map<String, dynamic>> _analyzeProjectContext(Map<String, dynamic> params, dynamic id) async {
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
  static Future<Map<String, dynamic>> _getErrorContext(Map<String, dynamic> params, dynamic id) async {
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
  static Future<Map<String, dynamic>> _getSuggestions(Map<String, dynamic> params, dynamic id) async {
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
  static Future<Map<String, dynamic>> _getHelp(Map<String, dynamic> params, dynamic id) async {
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

  /// Self-improvement analysis for the MCP server itself
  static Future<Map<String, dynamic>> _selfImprove(Map<String, dynamic> params, dynamic id) async {
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
    final analysisType = arguments['analysis_type'] as String? ?? 'all';
    final autoFix = arguments['auto_fix'] as bool? ?? false;
    
    try {
      final projectPath = Directory.current.path;
      final analyzer = ProjectAnalyzer(projectPath: projectPath);
      final context = await analyzer.analyzeProjectContext();
      
      final analysis = <String, dynamic>{};
      
      switch (analysisType) {
        case 'deprecated_apis':
          analysis['deprecated_apis'] = await _analyzeDeprecatedApis(context);
          break;
        case 'performance':
          analysis['performance'] = await _analyzePerformance(context);
          break;
        case 'code_quality':
          analysis['code_quality'] = await _analyzeCodeQuality(context);
          break;
        case 'all':
          analysis['deprecated_apis'] = await _analyzeDeprecatedApis(context);
          analysis['performance'] = await _analyzePerformance(context);
          analysis['code_quality'] = await _analyzeCodeQuality(context);
          break;
        default:
          return {
            'jsonrpc': '2.0',
            'id': id,
            'error': {
              'code': -32602,
              'message': 'Invalid analysis_type: $analysisType',
              'data': {
                'valid_types': ['deprecated_apis', 'performance', 'code_quality', 'all'],
                'default': 'all'
              }
            }
          };
      }
      
      // Run final dart analyze check to catch any code generation issues
      final validationResult = await _runFinalValidation(projectPath);
      
      final response = {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'success': true,
          'analysis_type': analysisType,
          'project_path': projectPath,
          'timestamp': DateTime.now().toIso8601String(),
          'analysis': analysis,
          'recommendations': _getRecommendations(analysis),
          'auto_fix_applied': autoFix,
          'final_validation': validationResult,
          'tip': validationResult['has_issues'] == false 
            ? 'Self-improvement completed successfully - no issues detected' 
            : '⚠️ Issues found after improvements - review validation results'
        }
      };
      
      return response;
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'success': false,
          'error': 'Self-improvement analysis failed: $e',
          'tip': 'Check the project structure and try again'
        }
      };
    }
  }

  /// Helper methods for enhanced responses

  static List<Map<String, String>> _getQuickFixes(String errorMessage) {
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

  static List<Map<String, String>> _getFallbackSuggestions(String? errorType) {
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

  static String _getPriority(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high': return '1';
      case 'medium': return '2';
      case 'low': return '3';
      default: return '2';
    }
  }

  /// Run final dart analyze validation to catch code generation issues
  static Future<Map<String, dynamic>> _runFinalValidation(String projectPath) async {
    try {
      final result = await Process.run('dart', ['analyze'], 
        workingDirectory: projectPath,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      
      final stdout = result.stdout as String;
      final stderr = result.stderr as String;
      final exitCode = result.exitCode;
      
      // Parse analyze output
      final lines = (stdout + stderr).split('\n');
      final issues = <Map<String, dynamic>>[];
      
      for (final line in lines) {
        if (line.trim().isNotEmpty && !line.startsWith('Analyzing')) {
          // Parse dart analyze output format: file:line:column: message
          final match = RegExp(r'^(.+?):(\d+):(\d+)?:?\s*(.+)$').firstMatch(line);
          if (match != null) {
            issues.add({
              'file': match.group(1),
              'line': int.tryParse(match.group(2) ?? '0'),
              'column': int.tryParse(match.group(3) ?? '0'),
              'message': match.group(4)?.trim() ?? line.trim(),
              'severity': _determineSeverity(match.group(4) ?? ''),
            });
          } else if (line.trim().contains('error') || line.trim().contains('warning') || line.trim().contains('info')) {
            issues.add({
              'file': 'unknown',
              'line': 0,
              'column': 0,
              'message': line.trim(),
              'severity': _determineSeverity(line),
            });
          }
        }
      }
      
      return {
        'has_issues': exitCode != 0,
        'exit_code': exitCode,
        'issues_count': issues.length,
        'issues': issues,
        'summary': issues.isEmpty 
          ? '✅ No issues detected - code generation successful'
          : '⚠️ ${issues.length} issue(s) found after improvements',
        'recommendations': issues.isNotEmpty ? _getValidationRecommendations(issues) : [],
      };
    } catch (e) {
      return {
        'has_issues': true,
        'error': 'Failed to run validation: $e',
        'summary': '❌ Validation check failed',
        'recommendations': ['Manually run `dart analyze` to check for issues'],
      };
    }
  }

  /// Determine severity of an issue based on message content
  static String _determineSeverity(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('error')) return 'error';
    if (msg.contains('warning')) return 'warning';
    if (msg.contains('info')) return 'info';
    return 'info';
  }

  /// Get recommendations for validation issues
  static List<String> _getValidationRecommendations(List<Map<String, dynamic>> issues) {
    final recommendations = <String>[];
    
    final errorCount = issues.where((i) => i['severity'] == 'error').length;
    final warningCount = issues.where((i) => i['severity'] == 'warning').length;
    
    if (errorCount > 0) {
      recommendations.add('🚨 Fix $errorCount error(s) before proceeding - these block compilation');
    }
    
    if (warningCount > 0) {
      recommendations.add('⚠️ Address $warningCount warning(s) - these may cause issues');
    }
    
    recommendations.add('🔧 Run `dart analyze --fix` to auto-fix some issues');
    recommendations.add('📝 Review generated code for syntax errors');
    recommendations.add('🔄 Consider reverting problematic changes');
    
    return recommendations;
  }

  /// Analyze deprecated APIs in the codebase
  static Future<Map<String, dynamic>> _analyzeDeprecatedApis(ProjectContext context) async {
    final deprecatedUsages = context.deprecatedApis;
    
    return {
      'count': deprecatedUsages.length,
      'files': deprecatedUsages.map((usage) => {
        'file': usage.filePath,
        'line': usage.line,
        'api': usage.deprecatedApi,
        'message': usage.message,
        'replacement': usage.replacement
      }).toList(),
      'recommendation': deprecatedUsages.length > 10 
          ? 'Many deprecated APIs found - prioritize updating these'
          : deprecatedUsages.length > 0 
            ? 'Consider updating deprecated APIs for future compatibility'
            : 'No deprecated APIs found - codebase is modern',
      'severity': deprecatedUsages.length > 20 ? 'high' : deprecatedUsages.length > 5 ? 'medium' : 'low'
    };
  }

  /// Analyze performance characteristics
  static Future<Map<String, dynamic>> _analyzePerformance(ProjectContext context) async {
    final classCount = context.classes.length;
    final customTypes = context.typeSystem.customTypes.length;
    final usesNullSafety = context.codeStyle.usesNullSafety;
    
    return {
      'complexity_score': _calculateComplexityScore(classCount, customTypes),
      'null_safety': usesNullSafety,
      'modern_features': context.codeStyle.usesExtensionMethods,
      'class_count': classCount,
      'custom_types': customTypes,
      'recommendations': [
        if (classCount > 20) 'Consider breaking down large classes',
        if (!usesNullSafety) 'Migrate to null safety for better type safety',
        if (customTypes > 30) 'Consider reducing custom type complexity',
      ].where((rec) => rec.isNotEmpty).toList(),
      'performance_tier': _getPerformanceTier(classCount, customTypes)
    };
  }

  /// Analyze code quality metrics
  static Future<Map<String, dynamic>> _analyzeCodeQuality(ProjectContext context) async {
    final deprecatedCount = context.deprecatedApis.length;
    final externalPackages = context.externalPackages.length;
    final dartCoreApis = context.dartCoreApis.length;
    
    return {
      'deprecated_api_count': deprecatedCount,
      'external_package_count': externalPackages,
      'dart_core_api_usage': dartCoreApis,
      'quality_score': _calculateQualityScore(deprecatedCount, externalPackages),
      'recommendations': [
        if (deprecatedCount > 0) 'Update deprecated APIs for better maintainability',
        if (externalPackages > 10) 'Review necessity of all external packages',
        if (dartCoreApis < 10) 'Consider using more Dart core APIs',
      ].where((rec) => rec.isNotEmpty).toList(),
      'quality_grade': _getQualityGrade(externalPackages, deprecatedCount)
    };
  }

  /// Helper methods for self-improvement analysis

  static int _calculateComplexityScore(int classCount, int customTypes) {
    final baseScore = (classCount * 2) + (customTypes * 3);
    return baseScore;
  }

  static String _getPerformanceTier(int classCount, int customTypes) {
    if (classCount > 50 || customTypes > 40) return 'complex';
    if (classCount > 20 || customTypes > 20) return 'moderate';
    return 'simple';
  }

  static int _calculateQualityScore(int deprecatedCount, int externalPackages) {
    final score = 100 - (deprecatedCount * 5) - (externalPackages * 2);
    return score.clamp(0, 100);
  }

  static String _getQualityGrade(int externalPackages, int deprecatedCount) {
    final score = _calculateQualityScore(deprecatedCount, externalPackages);
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  static List<String> _getRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <String>[];
    
    if (analysis.containsKey('deprecated_apis')) {
      final deprecated = analysis['deprecated_apis'] as Map<String, dynamic>;
      final count = deprecated['count'] as int;
      if (count > 0) {
        recommendations.add('Update $count deprecated APIs for better maintainability');
      }
    }
    
    if (analysis.containsKey('performance')) {
      final performance = analysis['performance'] as Map<String, dynamic>;
      final tier = performance['performance_tier'] as String;
      if (tier == 'complex') {
        recommendations.add('Consider breaking down large classes for better maintainability');
      }
    }
    
    if (analysis.containsKey('code_quality')) {
      final quality = analysis['code_quality'] as Map<String, dynamic>;
      final grade = quality['quality_grade'] as String;
      if (grade != 'A') {
        recommendations.add('Improve code quality to achieve grade A');
      }
    }
    
    return recommendations;
  }
}
