#!/usr/bin/env ruby
# Clipboard Server - A simple MCP server for clipboard operations
#
# Prerequisites:
#   - Ruby (any recent version)
#   - Bundler gem (gem install bundler)
#   The rest of dependencies will be installed automatically.
#
# Usage: ruby clipboard_copy_paste.rb [options]
#   -l, --log FILE         Path to log file (default: ./logs/mcp-server.log)
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
#         "/full-path-to/server-directory/clipboard_copy_paste.rb",
#         "--log",
#         "/full-path-to/server-directory/logs/claude-run.log"
#       ],
#       "workingDirectory": "/full-path-to/server-directory"
#     }
#   }
# }
#
# Configuration:
#   MCP_LOG_FILE - Path to log file (default: ./logs/mcp-server.log)
#

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "fast-mcp", "1.0.0" #, path: File.expand_path("../../", __FILE__)
  gem "pry"
  gem "rack" # looks like rack is running depency, even when we are using only stdio
end

require "fast_mcp"

# Parse command line arguments
require "optparse"

# Configure default log path with ENV var fallback
# FastMCP 1.0.0 we don't have logger in stdio transport layer
# FastMcp::Logger.log_path = ENV['MCP_LOG_FILE'] || File.join(Dir.pwd, 'logs', 'mcp-server.log')

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-l", "--log FILE", String, "Path to log file (default: ./logs/mcp-server.log)") do |file|
    # FastMcp::Logger.log_path = file
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

class ClipboardPaste < FastMcp::Tool
  description "Read text from the clipboard"

  def call
    case RUBY_PLATFORM
    when /darwin/
      `pbpaste`.strip
    when /linux/
      `xclip -selection clipboard -o 2>/dev/null || xsel -o -b 2>/dev/null`.strip
    when /mswin|mingw|cygwin/
      `powershell -command "Get-Clipboard" 2>/dev/null`.strip
    else
      raise "Platform #{RUBY_PLATFORM} not supported for clipboard operations"
    end
  rescue => e
    raise "❌ Error reading from clipboard: #{e.message}"
  end
end

class ClipboardCopy < FastMcp::Tool
  description "Write text to the clipboard"

  arguments do
    required(:content).filled(:string).description("Text content to write to clipboard")
  end

  def call(content:)
    case RUBY_PLATFORM
    when /darwin/
      IO.popen('pbcopy', 'w') { |io| io.write(content) }
    when /linux/
      IO.popen('xclip -selection clipboard', 'w') { |io| io.write(content) } rescue
      IO.popen('xsel -i -b', 'w') { |io| io.write(content) }
    when /mswin|mingw|cygwin/
      # Use PowerShell to set clipboard
      IO.popen("powershell -command \"Set-Clipboard -Value '#{content.gsub("'", "''")}'\"", 'w')
    else
      raise "Platform #{RUBY_PLATFORM} not supported for clipboard operations"
    end

    "✅ Text copied to clipboard"
  rescue => e
    raise "❌ Error writing to clipboard: #{e.message}"
  end
end

# Create and configure the MCP server
server = FastMcp::Server.new(
  name: "Clipboard Helper Server",
  version: "0.1.0"
)

# Register our resource and tool with the server
server.register_tools(ClipboardCopy, ClipboardPaste)

# Start the server in stdio mode
begin
  server.start
rescue => e
  puts "Failed to start server: #{e.message}"
  exit 1
end
