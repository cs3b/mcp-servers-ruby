#!/usr/bin/env ruby
# Clipboard Server - A simple MCP server for clipboard operations
#
# Prerequisites:
#   - Ruby (any recent version)
#   - Bundler gem (gem install bundler)
#   The rest of dependencies will be installed automatically.
#
# Usage: ruby clipboard.rb [options]
#   -h, --help             Show help message
#
# Claude Desktop Setup:
# Add this to your Claude Desktop config file (~/.config/Claude/claude_desktop_config.json):
#
# {
#   "mcpServers": {
#     "clipboard-helper": {
#       "name": "Clipboard Helper",
#       "transport": "stdio",
#       "command": "/full-path-to/ruby",
#       "args": [
#         "/full-path-to/server-directory/clipboard.rb"
#       ],
#       "workingDirectory": "/full-path-to/server-directory"
#     }
#   }
# }
#

ENV['LC_ALL'] = 'en_US.UTF-8'
ENV['LANG'] = 'en_US.UTF-8'

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "fast-mcp", "1.1.2", path: File.expand_path('../../../windsurf/fast-mcp', __FILE__)
  gem "clipboard"
  gem "ffi", platforms: [:mswin, :mingw] # Necessary on Windows
  gem "rack" # looks like rack is running depency, even when we are using only stdio
end

require "fast_mcp"
require "clipboard"
require "json"

# Parse command line arguments
require "optparse"

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Log the clipboard implementation being used
# puts "Using clipboard implementation: #{Clipboard.implementation}"

class ClipboardRead < FastMcp::Tool
  description "Read text from the system clipboard and return its contents as a string. This operation retrieves whatever text is currently stored in the clipboard without modifying it."

  def call
    begin
      content = Clipboard.paste
      # Handle Windows UTF-16LE encoding
      if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
        content = content.encode('UTF-8')
      end
      content.strip
    rescue => e
      raise "❌ Error reading from clipboard: #{e.message}"
    end
  end
end

class ClipboardWrite < FastMcp::Tool
  description "Write text to the system clipboard, replacing any existing clipboard content. The provided text will be available for pasting in any application on the system."

  arguments do
    required(:content).filled(:string).description("Text content to write to clipboard. This can be any string content including plain text, code snippets, or structured data as text.")
  end

  def call(content:)
    begin
      Clipboard.copy(content)
      "✅ Text copied to clipboard"
    rescue => e
      raise "❌ Error writing to clipboard: #{e.message}"
    end
  end
end

class ClipboardClear < FastMcp::Tool
  description "Clear all contents from the system clipboard, leaving it empty. This removes any text that was previously copied."

  def call
    begin
      Clipboard.clear
      "✅ Clipboard cleared"
    rescue => e
      raise "❌ Error clearing clipboard: #{e.message}"
    end
  end
end

# Linux-specific tool for accessing different selections
if RUBY_PLATFORM =~ /linux/
  class ClipboardSelectRead < FastMcp::Tool
    description "Read text from a specific clipboard selection on Linux systems. Linux has multiple clipboard buffers (selections) that can store content independently."

    arguments do
      required(:selection).filled(:string).description("Clipboard selection to use: 'clipboard' (standard clipboard), 'primary' (selected text), or 'secondary' (rarely used)")
    end

    def call(selection:)
      begin
        content = Clipboard.paste(selection)
        content.strip
      rescue => e
        raise "❌ Error reading from clipboard selection: #{e.message}"
      end
    end
  end

  class ClipboardSelectWrite < FastMcp::Tool
    description "Write text to a specific clipboard selection on Linux systems. This allows targeting a particular clipboard buffer rather than writing to all selections."

    arguments do
      required(:content).filled(:string).description("Text content to write to the specified clipboard selection")
      required(:selection).filled(:string).description("Clipboard selection to use: 'clipboard' (standard clipboard), 'primary' (selected text), or 'secondary' (rarely used)")
    end

    def call(content:, selection:)
      begin
        Clipboard.copy(content, clipboard: selection)
        "✅ Text copied to clipboard selection: #{selection}"
      rescue => e
        raise "❌ Error writing to clipboard selection: #{e.message}"
      end
    end
  end
end

# Create and configure the MCP server
server = FastMcp::Server.new(
  name: "Clipboard Helper Server",
  version: "0.1.0"
)

# Register our tools with the server
server.register_tools(ClipboardWrite, ClipboardRead, ClipboardClear)

# Register Linux-specific tools if on Linux
if RUBY_PLATFORM =~ /linux/
  server.register_tools(ClipboardSelectRead, ClipboardSelectWrite)
end

# Start the server in stdio mode
begin
  server.start
rescue => e
  puts "Failed to start server: #{e.message}"
  exit 1
end
