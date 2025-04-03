# MCP Servers Ruby Examples

This repository contains a collection of MCP (Machine Control Protocol) server implementations and utilities written in Ruby. These tools are designed to provide various system-level functionalities through a standardized protocol interface.

## What is MCP?

MCP (Machine Control Protocol) is a protocol for interacting with system-level operations in a controlled and secure manner. The implementations in this repository demonstrate how to create MCP servers that handle various system operations.

## Cost Efficiency

When using Claude AI to generate similar tools, the typical cost ranges from $0.01-$0.02 per tool (approximately 300-400 lines of Ruby code). This makes it a cost-effective approach for developing custom system utilities.

## Available Tools

### Operating System Utilities
### Media Server Utilities

- [Media Transcription](media/transcribe.md) - Handles media processing operations:
  - Audio file uploading and management
  - WAV transcoding using ffmpeg
  - Audio transcription via Whisper
  - Progress tracking and notifications
  
- [Content Summarization](media/summarize_content.rb) - Intelligent content analysis:
  - Transcript/article summarization
  - Multi-level prompt generation
  - Content comparison and delta analysis
  - Bias detection and insights extraction

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
```

Parameters:
- `SERVER_PATH`: Path to the MCP server implementation
- `BASE_PATH`: Base directory for the server (defaults to current directory)
### Prompt Templates
The media servers use XML-based prompt templates located in `media/prompts/`:

- `summarize.transcript.xml.erb` - For transcript analysis
- `whats.new.assistant.xml.erb` - For content comparison (assistant)
- `whats.new.user.xml.erb` - For content comparison (user)

Example:
```bash
./mcp_install claude_desktop ./os/clipboard.rb ~/projects/mcp-servers
```

For Claude Desktop, the installer will:
1. Generate server configuration
2. Update Claude Desktop's configuration file (if found)
3. Display the generated configuration for manual installation if needed
