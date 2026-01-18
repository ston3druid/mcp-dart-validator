# MCP Integration

This document explains how to use the Dart Validation MCP server with AI assistants and IDEs.

## 🚀 Quick Start

The MCP server provides a simple way to integrate Dart validation with AI assistants through the Model Context Protocol.

### Start the MCP Server

```bash
dart run bin/mcp_validation_server.dart
```

### Configure Clients

#### Gemini CLI

Add to `~/.gemini/settings.json` or `.gemini/settings.json`:

```json
{
  "mcpServers": {
    "dart-validation": {
      "command": "dart",
      "args": ["run", "bin/mcp_validation_server.dart"],
      "cwd": "/path/to/your/project"
    }
  }
}
```

#### VS Code

Add to your VS Code settings:

```json
{
  "dart.mcpServer": true,
  "mcpServers": {
    "dart-validation": {
      "command": "dart",
      "args": ["run", "bin/mcp_validation_server.dart"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

#### Cursor

Add to your Cursor MCP configuration:

```json
{
  "mcpServers": {
    "dart-validation": {
      "command": "dart",
      "args": ["run", "bin/mcp_validation_server.dart"],
      "cwd": "."
    }
  }
}
```

## 🔧 Available Tools

### validate_dart_project

Validates a Dart project using dart analyze.

**Parameters:**
- `project_path` (string, optional): Path to the Dart project (default: current directory)
- `exclude_paths` (array, optional): Paths to exclude from analysis
- `verbose` (boolean, optional): Show detailed progress and error information
- `format` (string, optional): Output format - "text" or "json" (default: "text")

**Example Usage:**
```json
{
  "name": "validate_dart_project",
  "arguments": {
    "project_path": ".",
    "exclude_paths": ["test", "build"],
    "verbose": true,
    "format": "json"
  }
}
```

## 📝 Example Interactions

### Basic Validation

**User:** "Please validate my Dart project"

**AI Assistant:** I'll validate your Dart project for you.

```json
{
  "name": "validate_dart_project",
  "arguments": {
    "project_path": "."
  }
}
```

### Validation with Exclusions

**User:** "Validate my project but exclude the test and build directories"

**AI Assistant:** I'll validate your project while excluding the test and build directories.

```json
{
  "name": "validate_dart_project",
  "arguments": {
    "project_path": ".",
    "exclude_paths": ["test", "build"],
    "verbose": true
  }
}
```

### JSON Output for Processing

**User:** "Validate my project and give me the results in JSON format"

**AI Assistant:** I'll validate your project and return the results in JSON format.

```json
{
  "name": "validate_dart_project",
  "arguments": {
    "project_path": ".",
    "format": "json"
  }
}
```

## 🎯 Benefits

- **Simplicity**: Minimal code, maximum functionality
- **Reliability**: Uses the proven dart analyze tool
- **Flexibility**: Configurable exclusions and output formats
- **Integration**: Works with any MCP-compatible client
- **Performance**: Fast validation with detailed reporting

## 🔍 How It Works

The MCP server is intentionally simple:

1. **Receives MCP requests** from AI assistants via stdin/stdout
2. **Translates requests** to CLI commands for your existing validation tool
3. **Executes validation** using your proven dart_mcp_tools.dart CLI
4. **Returns results** in MCP-compatible format

This approach keeps the code minimal while leveraging all the features of your existing validation tool.

## 🛠️ Architecture

```
AI Assistant → MCP Protocol → Simple Wrapper → Your CLI Tool → Results
```

The wrapper is only ~90 lines of code and handles:
- MCP protocol parsing
- Command translation
- Process execution
- Result formatting

## 📋 Requirements

- Dart SDK 3.9+
- Your dart_validation_mcp project
- MCP-compatible client (Gemini, Cursor, VS Code, etc.)

## 🔧 Troubleshooting

### Server Not Starting

Ensure you're in the project directory:
```bash
cd /path/to/dart_validation_mcp
dart run bin/mcp_validation_server.dart
```

### Client Can't Connect

Check your MCP configuration:
- Command path is correct
- Working directory is set
- Server is running

### Validation Fails

Test the CLI directly:
```bash
dart run bin/dart_mcp_tools.dart validate
```

## 📚 More Information

- [Main README](README.md)
- [API Reference](API_REFERENCE.md)
- [Production Guide](PRODUCTION.md)
