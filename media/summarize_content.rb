#!/usr/bin/env ruby
# Content Summarization Server - An MCP server for generating content summaries and comparisons
#
# Prerequisites:
#   - Ruby (any recent version)
#   - Bundler gem (gem install bundler)
#   The rest of dependencies will be installed automatically.
#
# Usage: ruby summarize_content.rb [options]
#   -d, --dir DIR          Working directory (default: current directory)
#   -p, --port PORT        Server port (default: 9293)
#   -m, --model-path PATH  Path to prompt generation model
#   -h, --help            Show help message
#
# Claude Desktop Setup:
# Add this to your Claude Desktop config file (~/.config/Claude/claude_desktop_config.json):
#
# {
#   "mcpServers": {
#     "content-summarizer": {
#       "name": "Content Summarization",
#       "transport": "stdio",
#       "command": "/full-path-to/ruby",
#       "args": [
#         "/full-path-to/server-directory/summarize_content.rb",
#         "--dir",
#         "/full-path-to/working-directory",
#         "--port",
#         "9293"
#       ],
#       "workingDirectory": "/full-path-to/server-directory"
#     }
#   }
# }
#
# Available Prompts:
#   - summarize_transcript: Generates summaries of video transcripts with content analysis
#   - whats_new: Compares documents to identify new or updated content
#
# Directory Structure:
#   /prompts/
#     summarize.transcript.xml.erb  - Template for transcript summarization
#     whats.new.assistant.xml.erb   - Template for content comparison (assistant)
#     whats.new.user.xml.erb        - Template for content comparison (user)
#

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "fast-mcp", "1.1.0"
  gem "rack"
end

require 'fast_mcp'
require 'erb'

  class SummarizeTranscriptPrompt < FastMcp::Prompt
    prompt_name 'summarize_transcript'
    description 'Summarize video transcripts with valuable content extraction and bias analysis'

    arguments do
      required(:transcript).filled(:string).description("The transcript to be summarized")
      optional(:meta).hash do
        optional(:title).filled(:string)
        optional(:source).filled(:string)
        optional(:language).filled(:string)
      end.description("Optional metadata about the content")
    end

    def call(transcript:, meta: {})
      assistant_template = File.read(File.join(File.dirname(__FILE__), 'prompts/summarize.transcript.xml.erb'))

      messages(
        assistant: ERB.new(assistant_template).result(binding),
        user: transcript
      )
    end
  end

  class WhatsNewPrompt < FastMcp::Prompt
    prompt_name 'whats_new'
    description 'Compare documents and identify new or updated content'

    arguments do
      required(:current_knowledge_document).filled(:string).description("Original document content")
      required(:new_document).filled(:string).description("New document content to compare")
      optional(:meta).hash do
        optional(:title).filled(:string)
        optional(:source).filled(:string)
        optional(:language).filled(:string)
      end.description("Optional metadata about the content")
    end

    def call(current_knowledge_document:, new_document:, meta: {})
      assistant_template = File.read(File.join(File.dirname(__FILE__), 'prompts/whats.new.assistant.xml.erb'))
      user_template = File.read(File.join(File.dirname(__FILE__), 'prompts/whats.new.user.xml.erb'))

      messages(
        assistant: ERB.new(assistant_template).result(binding),
        user: ERB.new(user_template).result(binding)
      )
    end
  end

# Create and configure the server
server = FastMcp::Server.new(
  name: 'prompt-generator',
  version: '1.0.0'
)

# Register the prompts
server.register_prompt(SummarizeTranscriptPrompt)
server.register_prompt(WhatsNewPrompt)

# Optional: Add a resource for caching
class DocumentCacheResource < FastMcp::Resource
  uri "cache/documents"
  resource_name "Document Cache"
  description "Cache of processed documents for comparison"
  mime_type "application/json"

  def initialize
    @cache = {}
  end

  def content
    JSON.generate(@cache)
  end

  def update_cache(id, content)
    @cache[id] = content
    server.notify_resource_updated(self.class.uri)
  end
end

server.register_resource(DocumentCacheResource)

# Start the server
if __FILE__ == $0
  # Parse command line arguments
  require 'optparse'

  options = {
    dir: Dir.pwd,
    port: 9293
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{$0} [options]"

    opts.on("-d", "--dir DIR", "Working directory") do |dir|
      options[:dir] = dir
    end

    opts.on("-p", "--port PORT", Integer, "Server port") do |port|
      options[:port] = port
    end

    opts.on("-m", "--model-path PATH", "Path to prompt generation model") do |path|
      options[:model_path] = path
    end
  end.parse!

  # Configure working directory
  Dir.chdir(options[:dir])

  # Start the server
  server.start
end
