import 'dart:io';
import 'package:pub_semver/pub_semver.dart';

/// Dynamic Dart version configuration manager
/// Adapts linting rules and standards based on available Dart version
class DartVersionConfig {
  static final Version _currentVersion = _getDartVersion();
  
  /// Get current Dart version
  static Version get currentVersion => _currentVersion;
  
  /// Detect if running Dart version supports specific features
  static bool supportsVersion(Version minVersion) => _currentVersion >= minVersion;
  
  /// Get appropriate analysis options for current Dart version
  static Map<String, dynamic> getAnalysisOptions() {
    final baseRules = <String, bool>{
      // Core rules that apply to all modern Dart versions
      'prefer_const_constructors': true,
      'prefer_const_literals_to_create_immutables': true,
      'prefer_const_declarations': true,
      'prefer_single_quotes': true,
      'sort_constructors_first': true,
      'sort_unnamed_constructors_first': true,
      
      // Language feature rules
      'avoid_function_literals_in_foreach_calls': true,
      'avoid_renaming_method_parameters': true,
      'avoid_returning_null_for_void': true,
      'avoid_types_as_parameter_names': true,
      'cascade_invocations': true,
      'comment_references': true,
      'empty_constructor_bodies': true,
      'empty_statements': true,
      'file_names': true,
      'hash_and_equals': true,
      'implementation_imports': true,
      'join_return_with_assignment': true,
      'non_constant_identifier_names': true,
      'null_closures': true,
      'omit_local_variable_types': true,
      'only_throw_errors': true,
      'overridden_fields': true,
      'parameter_assignments': true,
      'prefer_adjacent_string_concatenation': true,
      'prefer_asserts_in_initializer_lists': true,
      'prefer_collection_literals': true,
      'prefer_conditional_assignment': true,
      'prefer_contains': true,
      'prefer_equal_for_default_values': true,
      'prefer_expression_function_bodies': true,
      'prefer_final_fields': true,
      'prefer_final_locals': true,
      'prefer_for_elements_to_map_fromIterable': true,
      'prefer_function_declarations_over_variables': true,
      'prefer_generic_function_type_aliases': true,
      'prefer_if_elements_to_conditional_expressions': true,
      'prefer_if_null_operators': true,
      'prefer_initializing_formals': true,
      'prefer_inlined_adds': true,
      'prefer_interpolation_to_compose_strings': true,
      'prefer_is_empty': true,
      'prefer_is_not_empty': true,
      'prefer_is_not_operator': true,
      'prefer_iterable_whereType': true,
      'prefer_null_aware_operators': true,
      'prefer_relative_imports': true,
      'prefer_spread_collections': true,
      'prefer_typing_uninitialized_variables': true,
      'provide_deprecation_message': true,
      'recursive_getters': true,
      'slash_for_doc_comments': true,
      'sort_child_properties_last': true,
      'test_types_in_equals': true,
      'throw_in_finally': true,
      'type_annotate_public_apis': true,
      'type_init_formals': true,
      'unawaited_futures': true,
      'unnecessary_await_in_return': true,
      'unnecessary_brace_in_string_interps': true,
      'unnecessary_const': true,
      'unnecessary_getters_setters': true,
      'unnecessary_lambdas': true,
      'unnecessary_new': true,
      'unnecessary_null_aware_assignments': true,
      'unnecessary_null_checks': true,
      'unnecessary_null_in_if_null_operators': true,
      'unnecessary_overrides': true,
      'unnecessary_parenthesis': true,
      'unnecessary_statements': true,
      'unnecessary_string_interpolations': true,
      'unnecessary_this': true,
      'unrelated_type_equality_checks': true,
      'unsafe_html': true,
      'use_function_type_syntax_for_parameters': true,
      'use_if_null_to_convert_nulls_to_bools': true,
      'use_is_even_rather_than_modulo': true,
      'use_key_in_widget_constructors': true,
      'use_late_for_private_fields_and_variables': true,
      'use_named_constants': true,
      'use_rethrow_when_possible': true,
      'use_setters_to_change_properties': true,
      'use_string_buffers': true,
      'use_test_throws_matchers': true,
      'use_to_and_as_if_applicable': true,
      'valid_regexps': true,
      'void_checks': true,
    };
    
    // Version-specific rule adjustments
    final versionSpecificRules = _getVersionSpecificRules();
    
    // Merge rules
    final allRules = Map<String, bool>.from(baseRules);
    allRules.addAll(versionSpecificRules);
    
    return {
      'rules': allRules,
      'version': _currentVersion.toString(),
      'features': _getSupportedFeatures(),
    };
  }
  
  /// Get version-specific rule configurations
  static Map<String, bool> _getVersionSpecificRules() {
    final rules = <String, bool>{};
    
    // Dart 2.19+ features
    if (supportsVersion(Version(2, 19, 0))) {
      rules['exhaustive_cases'] = true;
    }
    
    // Dart 3.0+ features
    if (supportsVersion(Version(3, 0, 0))) {
      rules['prefer_final_in_for_each'] = true;
      rules['prefer_for_elements_to_map_fromIterable'] = true;
      rules['prefer_if_elements_to_conditional_expressions'] = true;
      rules['use_function_type_syntax_for_parameters'] = true;
    }
    
    // Dart 3.1+ features
    if (supportsVersion(Version(3, 1, 0))) {
      rules['prefer_spread_collections'] = true;
    }
    
    // Dart 3.3+ features
    if (supportsVersion(Version(3, 3, 0))) {
      rules['use_is_even_rather_than_modulo'] = true;
    }
    
    // Dart 3.4+ features
    if (supportsVersion(Version(3, 4, 0))) {
      rules['use_if_null_to_convert_nulls_to_bools'] = true;
    }
    
    // Practical adjustments based on version
    if (supportsVersion(Version(3, 10, 0))) {
      // Allow double literals for clarity in newer versions
      rules['prefer_int_literals'] = false;
      rules['unnecessary_raw_strings'] = false;
      rules['unnecessary_string_escapes'] = false;
    } else {
      // Stricter rules for older versions
      rules['prefer_int_literals'] = true;
      rules['unnecessary_raw_strings'] = true;
      rules['unnecessary_string_escapes'] = true;
    }
    
    return rules;
  }
  
  /// Get supported features for current Dart version
  static Map<String, bool> _getSupportedFeatures() {
    return {
      'pattern_matching': supportsVersion(Version(3, 0, 0)),
      'sealed_classes': supportsVersion(Version(3, 0, 0)),
      'records': supportsVersion(Version(3, 0, 0)),
      'class_modifiers': supportsVersion(Version(3, 0, 0)),
      'exhaustive_switching': supportsVersion(Version(3, 0, 0)),
      'if_elements': supportsVersion(Version(3, 0, 0)),
      'collection_for': supportsVersion(Version(3, 0, 0)),
      'spread_collections': supportsVersion(Version(3, 1, 0)),
      'super_parameters': supportsVersion(Version(2, 17, 0)),
      'named_arguments_anywhere': supportsVersion(Version(2, 17, 0)),
      'type_inference': supportsVersion(Version(2, 12, 0)),
      'null_safety': supportsVersion(Version(2, 12, 0)),
    };
  }
  
  /// Detect current Dart version
  static Version _getDartVersion() {
    try {
      final result = Process.runSync('dart', ['--version']);
      final output = result.stdout as String;
      
      // Parse version from output like "Dart SDK version: 3.10.3 (stable)"
      final versionMatch = RegExp(r'Dart SDK version: (\d+)\.(\d+)\.(\d+)').firstMatch(output);
      if (versionMatch != null) {
        final major = int.parse(versionMatch.group(1)!);
        final minor = int.parse(versionMatch.group(2)!);
        final patch = int.parse(versionMatch.group(3)!);
        return Version(major, minor, patch);
      }
    } catch (e) {
      // Fallback to a reasonable default
      print('Warning: Could not detect Dart version, using 3.10.0 as fallback');
      return Version(3, 10, 0);
    }
    
    return Version(3, 10, 0); // Fallback
  }
  
  /// Generate analysis_options.yaml content dynamically
  static String generateAnalysisOptionsYaml({
    bool excludeTests = true,
    bool excludeGenerated = true,
    Map<String, bool>? customRules,
  }) {
    final config = getAnalysisOptions();
    final rules = Map<String, bool>.from(config['rules'] as Map);
    
    // Apply custom rules if provided
    if (customRules != null) {
      rules.addAll(customRules);
    }
    
    final buffer = StringBuffer();
    
    // Use official Dart documentation format
    buffer.writeln('# Analysis Options for Dart ${config['version']}');
    buffer.writeln('# Generated using official Dart lints standards');
    buffer.writeln('# See: https://dart.dev/tools/linter-rules');
    buffer.writeln();
    buffer.writeln('include: package:flutter_lints/flutter.yaml');
    buffer.writeln();
    buffer.writeln('analyzer:');
    buffer.writeln('  exclude:');
    
    if (excludeGenerated) {
      buffer.writeln('    - "**/*.g.dart"');
      buffer.writeln('    - "**/*.freezed.dart"');
    }
    
    if (excludeTests) {
      buffer.writeln('    - "bin/**"');
      buffer.writeln('    - "test/**"');
    }
    
    buffer.writeln();
    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    
    // Sort rules for consistent output (official format)
    final sortedRules = Map.fromEntries(
      rules.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    for (final entry in sortedRules.entries) {
      buffer.writeln('    ${entry.key}: ${entry.value}');
    }
    
    buffer.writeln();
    buffer.writeln('# Dart ${config['version']} Features:');
    final features = config['features'] as Map<String, bool>;
    for (final entry in features.entries) {
      buffer.writeln('# - ${entry.key}: ${entry.value}');
    }
    
    return buffer.toString();
  }
}
