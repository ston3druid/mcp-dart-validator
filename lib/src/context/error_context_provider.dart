import 'dart:io';
import '../models/context_models.dart';

/// Provides context for errors to help AI assistants give better suggestions
class ErrorContextProvider {
  final String projectPath;

  ErrorContextProvider({required this.projectPath});

  /// Get context for a specific error
  Future<ErrorContext> getErrorContext(
    String errorMessage,
    String filePath,
    int? line,
    int? column,
  ) async {
    final similarIssues = await _findSimilarIssues(errorMessage);
    final solutionsThatWorked = await _findSolutionsThatWorked(errorMessage);
    final relatedClasses = await _findRelatedClasses(filePath, line);
    final availableApis = await _findAvailableApis(errorMessage);
    final importSuggestions = await _suggestImports(errorMessage);

    return ErrorContext(
      errorMessage: errorMessage,
      filePath: filePath,
      line: line,
      column: column,
      similarIssues: similarIssues,
      solutionsThatWorked: solutionsThatWorked,
      relatedClasses: relatedClasses,
      availableApis: availableApis,
      importSuggestions: importSuggestions,
    );
  }

  /// Find similar issues in the project
  Future<List<String>> _findSimilarIssues(String errorMessage) async {
    final similarIssues = <String>[];
    
    // Extract keywords from error message
    final keywords = _extractKeywords(errorMessage);
    
    final files = await _findDartFiles().toList();
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          for (final keyword in keywords) {
            if (line.toLowerCase().contains(keyword.toLowerCase()) && 
                (line.contains('error') || line.contains('Error'))) {
              similarIssues.add('${file.path}:${lines.indexOf(line) + 1}: $line');
            }
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return similarIssues.take(5).toList();
  }

  /// Find solutions that worked for similar errors
  Future<List<String>> _findSolutionsThatWorked(String errorMessage) async {
    final solutions = <String>[];
    
    // Common error patterns and their solutions
    final errorPatterns = {
      'null': [
        'Add null check before accessing',
        'Use null-aware operator (?.)',
        'Use null assertion (!)',
        'Initialize variables properly',
      ],
      'undefined': [
        'Initialize variable before use',
        'Check if variable is defined',
        'Add default value',
      ],
      'not found': [
        'Check import statements',
        'Verify file path',
        'Ensure dependency is added',
      ],
      'type': [
        'Check variable type',
        'Add type annotation',
        'Use proper casting',
        'Import required types',
      ],
      'async': [
        'Add await keyword',
        'Make function async',
        'Handle Future properly',
        'Use then() or async/await',
      ],
      'list': [
        'Check list bounds',
        'Use isEmpty() before access',
        'Use safe indexing',
        'Initialize list properly',
      ],
    };
    
    for (final pattern in errorPatterns.entries) {
      if (errorMessage.toLowerCase().contains(pattern.key)) {
        solutions.addAll(pattern.value);
      }
    }
    
    return solutions;
  }

  /// Find classes related to the error location
  Future<List<String>> _findRelatedClasses(String filePath, int? line) async {
    final relatedClasses = <String>[];
    
    try {
      final file = File(filePath);
      if (!await file.exists()) return relatedClasses;
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // Look for class definitions near the error
      final startLine = (line ?? 0) - 10;
      final endLine = (line ?? 0) + 10;
      
      for (int i = startLine.clamp(0, lines.length - 1); 
           i <= endLine.clamp(0, lines.length - 1); i++) {
        final lineContent = lines[i];
        if (lineContent.contains('class ')) {
          final match = RegExp(r'class\s+(\w+)').firstMatch(lineContent);
          if (match != null) {
            relatedClasses.add(match.group(1)!);
          }
        }
      }
    } catch (e) {
      // Skip if file can't be read
    }
    
    return relatedClasses;
  }

  /// Find available APIs that could solve the error
  Future<List<String>> _findAvailableApis(String errorMessage) async {
    final apis = <String>[];
    
    // Common API suggestions based on error patterns
    final errorToApi = {
      'file': ['File.readAsString()', 'File.writeAsString()', 'File.exists()'],
      'directory': ['Directory.list()', 'Directory.exists()', 'Directory.current'],
      'http': ['http.get()', 'http.post()', 'http.Request'],
      'string': ['String.split()', 'String.contains()', 'String.isEmpty()'],
      'list': ['List.add()', 'List.remove()', 'List.contains()'],
      'map': ['Map.putIfAbsent()', 'Map.remove()', 'Map.containsKey()'],
      'future': ['Future.value()', 'Future.delayed()', 'Future.wait()'],
      'stream': ['Stream.fromIterable()', 'Stream.listen()', 'StreamController()'],
      'datetime': ['DateTime.now()', 'DateTime.parse()', 'DateTime.add()'],
      'uri': ['Uri.parse()', 'Uri.http()', 'Uri.file()'],
    };
    
    for (final pattern in errorToApi.entries) {
      if (errorMessage.toLowerCase().contains(pattern.key)) {
        apis.addAll(pattern.value);
      }
    }
    
    return apis;
  }

  /// Suggest imports that might help
  Future<List<String>> _suggestImports(String errorMessage) async {
    final imports = <String>[];
    
    // Common import suggestions based on error patterns
    final errorToImport = {
      'file': ["import 'dart:io';"],
      'directory': ["import 'dart:io';"],
      'http': ["import 'package:http/http.dart';"],
      'async': ["import 'dart:async';"],
      'convert': ["import 'dart:convert';"],
      'math': ["import 'dart:math' as math;"],
      'collection': ["import 'dart:collection';"],
      'uri': ["import 'dart:uri';"],
      'path': ["import 'package:path/path.dart';"],
      'json': ["import 'dart:convert';"],
    };
    
    for (final pattern in errorToImport.entries) {
      if (errorMessage.toLowerCase().contains(pattern.key)) {
        imports.addAll(pattern.value);
      }
    }
    
    return imports;
  }

  /// Extract keywords from error message
  List<String> _extractKeywords(String errorMessage) {
    // Remove common words and extract meaningful keywords
    final commonWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'down', 'out', 'over', 'under', 'again', 'further', 'then',
      'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both',
      'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not',
      'only', 'own', 'same', 'so', 'than', 'too', 'very', 'can', 'will', 'just',
      'don', 'should', 'would', 'could',
    };
    
    return errorMessage
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty && !commonWords.contains(word.toLowerCase()))
        .where((word) => word.length > 2)
        .toList();
  }

  Stream<File> _findDartFiles() async* {
    final dir = Directory(projectPath);
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (!entity.path.contains('.dart_tool') && 
            !entity.path.contains('build')) {
          yield entity;
        }
      }
    }
  }
}
