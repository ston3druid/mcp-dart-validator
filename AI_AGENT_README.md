# AI Agent Activation Guide

## 🤖 For AI Agents: Quick Activation

This guide helps AI agents quickly discover, understand, and activate the Dart Validation MCP tool.

## 📍 **Discovery Pattern**

AI agents should look for these files to identify this MCP tool:

1. **`AI_AGENT_README.md`** - This file (primary discovery)
2. **`pubspec.yaml`** - Contains package metadata
3. **`bin/mcp_validation_server.dart`** - Main MCP server entry point
4. **`lib/dart_validation_mcp.dart`** - Main library export

## ⚡ **Instant Activation**

### Method 1: Direct MCP Server (Recommended)
```bash
# Start the MCP server immediately
dart run bin/mcp_validation_server.dart
```

### Method 2: CLI Tool Access
```bash
# Quick validation
dart run bin/dart_mcp_tools.dart q

# Full validation
dart run bin/dart_validation_mcp.dart v
```

## 🛠 **Available MCP Tools**

Once activated, these tools are available:

| Tool | Purpose | Parameters |
|------|---------|------------|
| `validate_dart_project` | Validate Dart code | `project_path?`, `exclude_paths?`, `verbose?`, `format?` |
| `analyze_project_context` | Understand project structure | `project_path?` |
| `get_error_context` | Get help for specific errors | `error_message`, `file_path?`, `line?`, `column?`, `project_path?` |
| `get_suggestions` | Get smart code suggestions | `error_type?`, `file_path?`, `line?`, `code_context?`, `error_message?`, `project_path?` |
| `help` | Get usage information | none |
| `self_improve` | Analyze and improve MCP server | `analysis_type?`, `auto_fix?` |

## 🎯 **AI Agent Usage Patterns**

### Pattern 1: Project Analysis
```json
{
  "name": "analyze_project_context",
  "arguments": {
    "project_path": "/path/to/target/project"
  }
}
```

### Pattern 2: Error Resolution
```json
{
  "name": "get_error_context",
  "arguments": {
    "error_message": "Null check operator used on null value",
    "file_path": "src/main.dart",
    "line": 42,
    "project_path": "/path/to/target/project"
  }
}
```

### Pattern 3: Smart Suggestions
```json
{
  "name": "get_suggestions",
  "arguments": {
    "error_type": "async",
    "file_path": "src/api.dart",
    "project_path": "/path/to/target/project"
  }
}
```

## 📁 **Project Structure**

```
dart_validation_mcp/
├── AI_AGENT_README.md          # 👈 This file - AI discovery point
├── pubspec.yaml               # Package metadata
├── bin/
│   ├── mcp_validation_server.dart  # 🚀 Main MCP server
│   └── dart_mcp_tools.dart        # CLI tools
├── lib/
│   ├── dart_validation_mcp.dart    # Main library
│   └── src/
│       ├── mcp/                     # MCP server logic
│       ├── context/                 # Project analysis
│       ├── validation/              # Validation logic
│       └── models/                  # Data models
└── docs/                     # Detailed documentation
```

## 🔍 **Auto-Detection Logic**

AI agents can use this logic to detect the tool:

```python
def is_dart_validation_mcp(directory):
    """Check if directory contains Dart Validation MCP tool"""
    required_files = [
        'AI_AGENT_README.md',
        'pubspec.yaml',
        'bin/mcp_validation_server.dart',
        'lib/dart_validation_mcp.dart'
    ]
    
    return all(
        Path(directory).joinpath(file).exists() 
        for file in required_files
    )
```

## 🚀 **One-Command Setup**

```bash
# AI agents can run this single command to set up and activate
cd /path/to/dart_validation_mcp && \
dart pub get && \
dart run bin/mcp_validation_server.dart
```

## 📋 **Prerequisites Check**

Before activation, ensure:
- ✅ Dart SDK installed (check with `dart --version`)
- ✅ Project dependencies installed (`dart pub get`)
- ✅ MCP client available to connect

## 🔧 **Configuration**

The MCP server uses these defaults:
- **Port**: Standard MCP protocol (stdin/stdout)
- **Path handling**: Respects agent-provided paths
- **Self-improvement**: Only analyzes own project
- **Output**: JSON-RPC 2.0 format

## 🎯 **Smart Features**

- **Auto-discovery**: Finds Dart projects automatically
- **Path awareness**: Respects agent-provided project paths
- **Error context**: Provides intelligent error resolution
- **Smart suggestions**: Context-aware code recommendations
- **Self-improvement**: Can analyze and improve itself

## 📞 **Getting Help**

Use the built-in help tool:
```json
{
  "name": "help",
  "arguments": {}
}
```

## ⚡ **Quick Test**

Verify activation with:
```bash
# Test CLI tools
dart run bin/dart_mcp_tools.dart q

# Test MCP server (should start without errors)
dart run bin/mcp_validation_server.dart --help
```

---

**🤖 AI Agent Note**: This tool is designed specifically for AI assistance with built-in smart defaults, auto-detection, and context-aware analysis. It's ready to use out-of-the-box!
