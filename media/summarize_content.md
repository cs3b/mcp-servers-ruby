# Prompt Generation Server Specification Document

## Overview
This server provides intelligent prompt generation based on transcript or article content. It supports generating summary prompts, multiple context-aware prompts depending on detail level, and delta prompts ("what's new") by comparing incoming content against known documents.

It is built in compliance with the [Model Context Protocol (MCP) 2025-03-26 specification](https://spec.modelcontextprotocol.io/specification/2025-03-26/) and integrates with the `fast-mcp` Ruby gem to provide a standard tool/resource API.

---

## Features

### 1. **Input Types**
- Accepts input as plain text, JSON-formatted transcript/article, or Markdown.
- Optional metadata may include:
  - Title
  - Source type (e.g., YouTube, blog, news article)
  - Author, date, tags, etc.

### 2. **Prompt Types Supported**

#### A. **Summary Prompt**
- Returns a natural-language prompt summarizing the entire content.
- Example: _"Summarize the key political arguments made in this interview."_

#### B. **Detailed Prompts**
- For long or structured input, generates multiple prompts:
  - Topic-specific prompts
  - Section-based prompts
  - Quote-based questions
- Example: _"What does the expert say about AI regulation?"_

#### C. **Delta Prompt (What's New)**
- Compares new document against a known existing document.
- Returns a prompt that captures **new, changed, or updated ideas**.
- Example: _"What updates are given in the new episode that were not covered previously?"_

---

## API Overview (MCP-Compliant)

### Tool: `generate_prompts`
```json
{
  "method": "tool/generate_prompts",
  "params": {
    "input_text": "<full transcript or article>",
    "type": "summary | detailed",
    "meta": {
      "title": "...",
      "source": "...",
      "language": "en"
    }
  }
}
```

### Tool: `generate_delta_prompt`
```json
{
  "method": "tool/generate_delta_prompt",
  "params": {
    "known_document": "...",
    "new_document": "...",
    "meta": {
      "title": "...",
      "source": "...",
      "language": "en"
    }
  }
}
```

### Example Response: `generate_prompts`
```json
{
  "result": {
    "prompts": [
      "Summarize the main economic themes discussed in the article.",
      "What is the expert's opinion on central bank policy?",
      "List the three most controversial statements from the speaker."
    ]
  }
}
```

---

## Runtime Behavior
- All operations are stateless and generate output on demand.
- Server may cache documents temporarily for diffing in delta mode.
- Language detection can be automatic if `language` param not provided.

---

## Configuration
| Option             | Description                                 |
|--------------------|---------------------------------------------|
| `--dir` or `-d`    | Optional working directory for temp storage |
| `--port`           | Server port (default: 9293)                 |
| `--model-path`     | Path to prompt generation model or binary   |

---

## Dependencies
- Ruby >= 3.0
- `fast-mcp` gem
- Optional: external LLM or summarizer backend
- Natural language diff engine (for delta prompt comparison)

---

## Future Extensions
- Topic tagging of prompts
- Streaming input and interactive prompt refinement
- Integration with citation/linking tools

---

## Notes
- All prompts are returned as plain text.
- Prompts should be clear, natural, and useful for downstream LLM usage.
- Server uses `$/progress` notifications when processing large or complex documents.

---


{"jsonrpc":"2.0","id":2,"method":"prompts/get","params":{"name":"SummarizeTranscriptPrompt","arguments":{"code":"def hello():\n    print('world')"}}}
