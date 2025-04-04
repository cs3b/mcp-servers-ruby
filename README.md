# MCP Servers Ruby Examples

This repository contains a collection of MCP (Machine Control Protocol) server implementations and utilities written in Ruby. It's more a place for experiments with MCP Servers.

## Available Tools

### Operating System Utilities

- [Filesystem Operations](os/filesystem.rb) - Handles file system operations including:
  - Reading files
  - Listing directory contents
  - Directory tree traversal
  - File creation and modification
  - File deletion
  - Patch application

- [Clipboard Operations](os/clipboard.rb) - Manages system clipboard interactions

## Installation

The repository provides a Thor-based installer script for setting up MCP servers with different Claude environments.

### Prerequisites

```bash
bundle install
```
The media servers require additional dependencies:

- ffmpeg (for audio transcoding)
- Whisper (for speech transcription)
- Ruby >= 3.0
- fast-mcp gem (1.1.0 or later)

### Installing MCP Servers

The `mcp_install` script provides commands for installing MCP servers for different Claude environments:

```bash
# For Claude Desktop
./mcp_install claude_desktop SERVER_PATH [BASE_PATH]

# For Claude Code
./mcp_install claude_code SERVER_PATH [BASE_PATH]

# For Windsurf
./mcp_install windsurf SERVER_PATH [BASE_PATH]
```

Parameters:
- `SERVER_PATH`: Path to the MCP server implementation
- `BASE_PATH`: Base directory for the server (defaults to current directory)
### Prompt Templates
The media servers use XML-based prompt templates located in `media/prompts/`:

- `summarize.transcript.xml.erb` - For transcript analysis
- `whats.new.assistant.xml.erb` - For content comparison (assistant)
- `whats.new.user.xml.erb` - For content comparison (user)

Examples:
```bash
# Install for Claude Desktop
./mcp_install claude_desktop ./os/clipboard.rb

# Install for Windsurf
./mcp_install windsurf ./os/clipboard.rb
```

The installer will:
1. Generate server configuration
2. Update configuration file if found:
   - Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windsurf: `~/.codeium/windsurf/mcp_config.json`
   - Claude Code: (configuration path varies)
3. Display the generated configuration for manual installation if needed
