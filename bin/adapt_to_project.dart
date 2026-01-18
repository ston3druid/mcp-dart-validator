#!/usr/bin/env dart

import 'dart:io';
import '../lib/src/project_analyzer.dart';

/// Tool to adapt MCP package to any project's specific Dart version and requirements
/// This tool makes the MCP package automatically adjust to different project environments
void main(List<String> args) async {
  final projectPath = args.isNotEmpty ? args[0] : Directory.current.path;
  
  print('🔍 Analyzing project: $projectPath');
  print('');
  
  try {
    // Analyze the project
    final analysis = await ProjectAnalyzer.generateProjectSpecificAnalysisOptions(projectPath);
    
    // Write the adapted analysis options
    final file = File('analysis_options.yaml');
    await file.writeAsString(analysis);
    
    print('✅ Successfully adapted analysis_options.yaml to project!');
    print('');
    print('📋 Generated configuration includes:');
    print('   - Project-specific Dart version detection');
    print('   - Flutter version compatibility');
    print('   - Dependency-aware rule adjustments');
    print('   - Project size optimizations');
    print('   - Generated file exclusions');
    print('');
    
    // Show what was detected
    print('🔍 Project detection results:');
    final lines = analysis.split('\n');
    final summaryStart = lines.indexWhere((line) => line.contains('# Project Analysis Summary:'));
    if (summaryStart != -1) {
      for (int i = summaryStart; i < lines.length; i++) {
        if (lines[i].startsWith('# ')) {
          print('   ${lines[i].substring(2)}');
        }
      }
    }
    
    print('');
    print('💡 Usage:');
    print('   dart bin/adapt_to_project.dart                    # Adapt to current directory');
    print('   dart bin/adapt_to_project.dart /path/to/project    # Adapt to specific project');
    print('');
    print('🔄 Re-run this tool when:');
    print('   - Project Dart version changes');
    print('   - New dependencies are added');
    print('   - Project structure significantly changes');
    
  } catch (e) {
    print('❌ Error adapting to project: $e');
    exit(1);
  }
}
