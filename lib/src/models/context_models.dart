/// Models for project context analysis and AI assistance
library context_models;

/// Project context information for AI assistance
class ProjectContext {
  final String projectPath;
  final List<String> dependencies;
  final Map<String, List<String>> imports;
  final Map<String, ClassInfo> classes;
  final List<String> dartCoreApis;
  final List<String> externalPackages;
  final List<DeprecatedApiUsage> deprecatedApis;
  final CodeStyleProfile codeStyle;
  final TypeSystemInfo typeSystem;
  final List<ErrorPattern> errorPatterns;

  const ProjectContext({
    required this.projectPath,
    required this.dependencies,
    required this.imports,
    required this.classes,
    required this.dartCoreApis,
    required this.externalPackages,
    required this.deprecatedApis,
    required this.codeStyle,
    required this.typeSystem,
    required this.errorPatterns,
  });
}

/// Information about a class in the project
class ClassInfo {
  final String name;
  final String filePath;
  final List<String> methods;
  final List<String> properties;
  final List<String> constructors;
  final String? superClass;
  final List<String> interfaces;

  const ClassInfo({
    required this.name,
    required this.filePath,
    required this.methods,
    required this.properties,
    required this.constructors,
    this.superClass,
    required this.interfaces,
  });
}

/// Deprecated API usage information
class DeprecatedApiUsage {
  final String filePath;
  final int? line;
  final String deprecatedApi;
  final String? replacement;
  final String message;

  const DeprecatedApiUsage({
    required this.filePath,
    this.line,
    required this.deprecatedApi,
    this.replacement,
    required this.message,
  });
}

/// Code style and patterns used in the project
class CodeStyleProfile {
  final List<String> asyncPatterns;
  final List<String> stateManagement;
  final List<String> architecturePatterns;
  final Map<String, int> namingConventions;
  final bool usesNullSafety;
  final bool usesExtensionMethods;

  const CodeStyleProfile({
    required this.asyncPatterns,
    required this.stateManagement,
    required this.architecturePatterns,
    required this.namingConventions,
    required this.usesNullSafety,
    required this.usesExtensionMethods,
  });
}

/// Type system information
class TypeSystemInfo {
  final List<String> customTypes;
  final List<String> genericTypes;
  final List<String> extensionMethods;
  final Map<String, String> typeAliases;

  const TypeSystemInfo({
    required this.customTypes,
    required this.genericTypes,
    required this.extensionMethods,
    required this.typeAliases,
  });
}

/// Common error patterns in the project
class ErrorPattern {
  final String pattern;
  final String description;
  final List<String> examples;
  final int frequency;
  final String? commonFix;

  const ErrorPattern({
    required this.pattern,
    required this.description,
    required this.examples,
    required this.frequency,
    this.commonFix,
  });
}

/// API usage report
class ApiUsageReport {
  final Map<String, int> dartCoreApis;
  final Map<String, int> externalPackages;
  final List<DeprecatedApiUsage> deprecatedApis;
  final List<String> unusedImports;

  const ApiUsageReport({
    required this.dartCoreApis,
    required this.externalPackages,
    required this.deprecatedApis,
    required this.unusedImports,
  });
}

/// Error context for better suggestions
class ErrorContext {
  final String errorMessage;
  final String filePath;
  final int? line;
  final int? column;
  final List<String> similarIssues;
  final List<String> solutionsThatWorked;
  final List<String> relatedClasses;
  final List<String> availableApis;
  final List<String> importSuggestions;

  const ErrorContext({
    required this.errorMessage,
    required this.filePath,
    this.line,
    this.column,
    required this.similarIssues,
    required this.solutionsThatWorked,
    required this.relatedClasses,
    required this.availableApis,
    required this.importSuggestions,
  });
}

/// Smart code suggestion based on context
class CodeSuggestion {
  final String description;
  final String code;
  final String explanation;
  final List<String> requiredImports;
  final List<String> relatedClasses;
  final String confidence;

  const CodeSuggestion({
    required this.description,
    required this.code,
    required this.explanation,
    required this.requiredImports,
    required this.relatedClasses,
    required this.confidence,
  });
}
