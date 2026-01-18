import '../models/context_models.dart';
import 'project_analyzer.dart';

/// Provides smart code suggestions based on project context
class SmartSuggester {
  final String projectPath;
  late final ProjectAnalyzer _analyzer;

  SmartSuggester({required this.projectPath}) {
    _analyzer = ProjectAnalyzer(projectPath: projectPath);
  }

  /// Get smart suggestions for a given context
  Future<List<CodeSuggestion>> getSuggestions({
    String? errorType,
    String? filePath,
    int? line,
    String? codeContext,
    String? errorMessage,
  }) async {
    final suggestions = <CodeSuggestion>[];
    
    final projectContext = await _analyzer.analyzeProjectContext();
    
    if (errorType != null) {
      suggestions.addAll(_getSuggestionsForError(errorType, projectContext));
    }
    
    if (codeContext != null) {
      suggestions.addAll(_getSuggestionsForContext(codeContext, projectContext));
    }
    
    if (errorMessage != null) {
      suggestions.addAll(_getSuggestionsForErrorMessage(errorMessage, projectContext));
    }
    
    // Sort by confidence and return top suggestions
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(5).toList();
  }

  /// Get suggestions for specific error types
  List<CodeSuggestion> _getSuggestionsForError(String errorType, ProjectContext context) {
    final suggestions = <CodeSuggestion>[];
    
    switch (errorType.toLowerCase()) {
      case 'null':
        suggestions.add(CodeSuggestion(
          description: 'Add null check before accessing',
          code: 'if (variable != null) { variable.method(); }',
          explanation: 'Check if variable is not null before accessing its methods',
          requiredImports: [],
          relatedClasses: [],
          confidence: 'high',
        ));
        
        suggestions.add(CodeSuggestion(
          description: 'Use null-aware operator',
          code: 'variable?.method()',
          explanation: 'Use ?. to safely access methods on nullable objects',
          requiredImports: [],
          relatedClasses: [],
          confidence: 'high',
        ));
        break;
        
      case 'async':
        suggestions.add(CodeSuggestion(
          description: 'Add await keyword',
          code: 'await asyncOperation()',
          explanation: 'Use await to wait for Future completion',
          requiredImports: ['dart:async'],
          relatedClasses: ['Future'],
          confidence: 'high',
        ));
        
        suggestions.add(CodeSuggestion(
          description: 'Make function async',
          code: 'Future<void> functionName() async { /* code */ }',
          explanation: 'Add async keyword to function signature',
          requiredImports: ['dart:async'],
          relatedClasses: ['Future'],
          confidence: 'medium',
        ));
        break;
        
      case 'file':
        suggestions.add(CodeSuggestion(
          description: 'Read file contents',
          code: 'final content = await File(path).readAsString();',
          explanation: 'Use File class to read file contents asynchronously',
          requiredImports: ['dart:io'],
          relatedClasses: ['File'],
          confidence: 'high',
        ));
        
        suggestions.add(CodeSuggestion(
          description: 'Check if file exists',
          code: 'if (await File(path).exists()) { /* code */ }',
          explanation: 'Use exists() to check file existence before operations',
          requiredImports: ['dart:io'],
          relatedClasses: ['File'],
          confidence: 'high',
        ));
        break;
        
      case 'list':
        suggestions.add(CodeSuggestion(
          description: 'Add item to list',
          code: 'list.add(item);',
          explanation: 'Use add() method to add items to a list',
          requiredImports: [],
          relatedClasses: ['List'],
          confidence: 'high',
        ));
        
        suggestions.add(CodeSuggestion(
          description: 'Check if list contains item',
          code: 'if (list.contains(item)) { /* code */ }',
          explanation: 'Use contains() to check if item exists in list',
          requiredImports: [],
          relatedClasses: ['List'],
          confidence: 'high',
        ));
        break;
        
      case 'http':
        suggestions.add(CodeSuggestion(
          description: 'Make HTTP GET request',
          code: 'final response = await http.get(Uri.parse(url));',
          explanation: 'Use http.get() to make GET requests',
          requiredImports: ['package:http/http.dart', 'dart:io'],
          relatedClasses: ['Uri', 'Response'],
          confidence: 'high',
        ));
        
        suggestions.add(CodeSuggestion(
          description: 'Make HTTP POST request',
          code: 'final response = await http.post(url, body: body);',
          explanation: 'Use http.post() to send data to server',
          requiredImports: ['package:http/http.dart', 'dart:io'],
          relatedClasses: ['Uri', 'Response'],
          confidence: 'high',
        ));
        break;
    }
    
    return suggestions;
  }

  /// Get suggestions based on code context
  List<CodeSuggestion> _getSuggestionsForContext(String codeContext, ProjectContext context) {
    final suggestions = <CodeSuggestion>[];
    
    // Suggest available classes from the project
    if (codeContext.contains('new ') && codeContext.contains('(')) {
      for (final className in context.classes.keys) {
        if (codeContext.contains(className)) {
          final classInfo = context.classes[className];
          suggestions.add(CodeSuggestion(
            description: 'Use ${className} class from project',
            code: 'final instance = ${className}();',
            explanation: 'Use the ${className} class that exists in your project',
            requiredImports: [],
            relatedClasses: [className],
            confidence: 'high',
          ));
        }
      }
    }
    
    // Suggest imports based on available packages
    if (codeContext.contains('http') && !codeContext.contains('import')) {
      if (context.dependencies.contains('http')) {
        suggestions.add(CodeSuggestion(
          description: 'Import http package',
          code: "import 'package:http/http.dart';",
          explanation: 'Add http package import for HTTP operations',
          requiredImports: [],
          relatedClasses: [],
          confidence: 'high',
        ));
      }
    }
    
    return suggestions;
  }

  /// Get suggestions based on error message
  List<CodeSuggestion> _getSuggestionsForErrorMessage(String errorMessage, ProjectContext context) {
    final suggestions = <CodeSuggestion>[];
    
    // Suggest based on common error patterns
    if (errorMessage.contains('undefined') || errorMessage.contains('not defined')) {
      // Find similar class names in the project
      final possibleClasses = _findSimilarClasses(errorMessage, context);
      for (final className in possibleClasses) {
        suggestions.add(CodeSuggestion(
          description: 'Use ${className} class',
          code: 'final instance = ${className}();',
          explanation: '${className} class found in your project',
          requiredImports: [],
          relatedClasses: [className],
          confidence: 'medium',
        ));
      }
    }
    
    if (errorMessage.contains('import')) {
      // Suggest missing imports
      final missingImports = _suggestMissingImports(errorMessage, context);
      for (final importStatement in missingImports) {
        suggestions.add(CodeSuggestion(
          description: 'Add import statement',
          code: importStatement,
          explanation: 'Add this import to resolve the error',
          requiredImports: [],
          relatedClasses: [],
          confidence: 'high',
        ));
      }
    }
    
    return suggestions;
  }

  /// Find classes with similar names to what's mentioned in error
  List<String> _findSimilarClasses(String errorMessage, ProjectContext context) {
    final similarClasses = <String>[];
    final words = errorMessage.split(RegExp(r'[^\w]'));
    
    for (final word in words) {
      if (word.length > 2) {
        for (final className in context.classes.keys) {
          if (_calculateSimilarity(word.toLowerCase(), className.toLowerCase()) > 0.7) {
            similarClasses.add(className);
          }
        }
      }
    }
    
    return similarClasses;
  }

  /// Suggest missing imports based on error message
  List<String> _suggestMissingImports(String errorMessage, ProjectContext context) {
    final imports = <String>[];
    
    // Common missing imports based on error patterns
    if (errorMessage.contains('File') && !context.dartCoreApis.contains('File')) {
      imports.add("import 'dart:io';");
    }
    
    if (errorMessage.contains('Directory') && !context.dartCoreApis.contains('Directory')) {
      imports.add("import 'dart:io';");
    }
    
    if (errorMessage.contains('Future') && !context.dartCoreApis.contains('Future')) {
      imports.add("import 'dart:async';");
    }
    
    if (errorMessage.contains('Uri') && !context.dartCoreApis.contains('Uri')) {
      imports.add("import 'dart:uri';");
    }
    
    if (errorMessage.contains('http') && !context.externalPackages.contains('http')) {
      imports.add("import 'package:http/http.dart';");
    }
    
    return imports;
  }

  /// Calculate similarity between two strings
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    if (longer.isEmpty) return 0.0;
    
    final editDistance = _levenshteinDistance(a, b);
    return (longer.length - editDistance) / longer.length;
  }

  /// Simple Levenshtein distance calculation
  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    
    for (int j = 0; j < b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,    // deletion
          matrix[i][j - 1] + 1,    // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }
}
