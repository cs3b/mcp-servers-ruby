#!/usr/bin/env ruby
# Filesystem Operations Server - A simple MCP server for file system operations
#
# Prerequisites:
#   - Ruby (any recent version)
#   - Bundler gem (gem install bundler)
#   The rest of dependencies will be installed automatically.
#
# Usage: ruby filesystem_operations.rb [options]
#   -d, --directory DIR     Base directory for filesystem operations (default: ./filesystem_workspace)
#   -h, --help             Show help message
#
# Claude Desktop Setup:
# Add this to your Claude Desktop config file (~/.config/Claude/claude_desktop_config.json):
#
# {
#   "mcpServers": {
#     "filesystem-ops": {
#       "name": "Filesystem Operations",
#       "transport": "stdio",
#       "command": "/full-path-to/ruby",
#       "args": [
#         "/full-path-to/server-directory/filesystem_operations.rb",
#         "--directory",
#         "/full-path-to-base-directory/filesystem_workspace"
#       ],
#       "workingDirectory": "/full-path-to/server-directory"
#     }
#   }
# }
#
# Configuration:
#   FILESYSTEM_BASE_DIR - Base directory for filesystem operations (default: ./filesystem_workspace)
#

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "fast-mcp", "1.1.1", path: File.expand_path('~/Projects/windsurf/fast-mcp'
  gem "rack" # looks like rack is running dependency, even when we are using only stdio
end

require "fast_mcp"

# File Operations
require "fileutils"
require "pathname"
require "find"

# Parse command line arguments
require "optparse"
require "singleton"

class Config
  include Singleton

  attr_reader :base_dir

  def initialize
    @base_dir = ENV["FILESYSTEM_BASE_DIR"] || "./filesystem_workspace"
  end

  def base_dir=(dir)
    raise ArgumentError, "Directory path cannot be empty" if dir.nil? || dir.empty?
    @base_dir = File.expand_path(dir)
    FileUtils.mkdir_p(@base_dir) unless File.directory?(@base_dir)
  end
end

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-d", "--directory DIR", "Base directory for filesystem operations (default: ./filesystem_workspace)") do |dir|
    Config.instance.base_dir = dir
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Helper module for path validation
module PathHelpers
  def self.validate_path(path, config)
    # Prevent directory traversal and ensure path is relative
    if path.include?("../") || path.start_with?("/")
      raise "Invalid path. Must be a relative path without directory traversal"
    end

    # Ensure full path is within the allowed base directory
    full_path = File.expand_path(File.join(config.base_dir, path))
    unless full_path.start_with?(config.base_dir)
      raise "Path must be within the allowed base directory"
    end

    full_path
  end

  def self.relativize_path(full_path, config)
    Pathname.new(full_path).relative_path_from(Pathname.new(config.base_dir)).to_s
  end
end

# Tools for filesystem operations
class ReadFileTool < FastMcp::Tool
  description "Read a file in the allowed directory"

  attributes do
    required(:path).filled(:string).description("Relative path to the file")
  end

  def call(path:)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    unless File.file?(full_path)
      raise "File not found: #{path}"
    end

    { content: File.read(full_path) }
  rescue => e
    raise "Error reading file: #{e.message}"
  end
end

class ListDirectoryTool < FastMcp::Tool
  description "List contents of a directory"

  request do
    required(:path).filled(:string).description("Relative path to the directory")
  end

  response do
    required(:entries).value(:array).description("List of directory entries")
    required(:types).value(:hash).description("Type of each entry (file or directory)")
  end

  def call(path:)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    unless File.directory?(full_path)
      raise "Directory not found: #{path}"
    end

    entries = Dir.entries(full_path).reject { |entry| entry == "." || entry == ".." }
    types = {}

    entries.each do |entry|
      entry_path = File.join(full_path, entry)
      types[entry] = File.directory?(entry_path) ? "directory" : "file"
    end

    { entries: entries, types: types }
  rescue => e
    raise "Error listing directory: #{e.message}"
  end
end

class ListDirectoryTreeTool < FastMcp::Tool
  description "List the entire tree structure of a directory"

  request do
    required(:path).filled(:string).description("Relative path to the directory")
  end

  response do
    required(:tree).value(:hash).description("Tree structure of the directory")
  end

  def call(path:)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    unless File.directory?(full_path)
      raise "Directory not found: #{path}"
    end

    tree = build_tree(full_path, config)
    { tree: tree }
  rescue => e
    raise "Error listing directory tree: #{e.message}"
  end

  private

  def build_tree(dir_path, config)
    result = {}

    Dir.entries(dir_path).reject { |entry| entry == "." || entry == ".." }.each do |entry|
      entry_path = File.join(dir_path, entry)

      if File.directory?(entry_path)
        result[entry] = { type: "directory", contents: build_tree(entry_path, config) }
      else
        result[entry] = { type: "file" }
      end
    end

    result
  end
end

# Tools for filesystem operations
class WriteFileToolTool < FastMcp::Tool
  description "Write content to a file (create or overwrite)"

  arguments do
    required(:path).filled(:string).description("Relative path to the file")
    required(:content).filled(:string).description("Content to write")
  end

  def call(path:, content:)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    # Create directory if it doesn't exist
    dir_path = File.dirname(full_path)
    FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)

    File.write(full_path, content)

    "✅ File written successfully to #{path}"
  rescue => e
    raise "❌ Error writing file: #{e.message}"
  end
end

class DeleteFileTool < FastMcp::Tool
  description "Delete a file or directory"

  arguments do
    required(:path).filled(:string).description("Relative path to the file or directory to delete")
    optional(:recursive).value(:bool).description("Delete directories recursively")
  end

  def call(path:, recursive: false)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    unless File.exist?(full_path)
      raise "Path not found: #{path}"
    end

    if File.directory?(full_path)
      if recursive
        FileUtils.rm_rf(full_path)
      else
        if Dir.empty?(full_path)
          FileUtils.rmdir(full_path)
        else
          raise "Directory not empty. Use recursive: true to delete recursively"
        end
      end
    else
      FileUtils.rm(full_path)
    end

    "✅ Successfully deleted #{path}"
  rescue => e
    raise "❌ Error deleting: #{e.message}"
  end
end

class ApplyPatchTool < FastMcp::Tool
  description "Apply a patch to a file"

  arguments do
    required(:path).filled(:string).description("Relative path to the file to patch")
    required(:patch).filled(:string).description("Patch content in unified diff format")
  end

  def call(path:, patch:)
    config = Config.instance
    full_path = PathHelpers.validate_path(path, config)

    unless File.file?(full_path)
      raise "File not found: #{path}"
    end

    # Create a temporary file for the patch
    patch_file = Tempfile.new("patch")
    begin
      patch_file.write(patch)
      patch_file.close

      # Apply the patch using the patch command
      result = system("patch", "-u", full_path, patch_file.path)
      unless result
        raise "Patch application failed. Make sure the patch format is correct"
      end

      "✅ Patch applied successfully to #{path}"
    ensure
      patch_file.unlink
    end
  rescue => e
    raise "❌ Error applying patch: #{e.message}"
  end
end

# Create and configure the MCP server
server = FastMcp::Server.new(
  name: "Filesystem Operations Server",
  version: "0.1.0"
)

# Register our tools with the server
server.register_tool(ReadFileTool)
server.register_tool(ListDirectoryTool)
server.register_tool(ListDirectoryTreeTool)

# Register our tools with the server
server.register_tool(WriteFileToolTool)
server.register_tool(DeleteFileTool)
server.register_tool(ApplyPatchTool)

# Start the server in stdio mode
begin
  server.start
rescue => e
  puts "Failed to start server: #{e.message}"
  exit 1
end
