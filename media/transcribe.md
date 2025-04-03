# MCP Server Specification Document

## Overview
The MCP Server is a media-processing server built on the [fast-mcp](https://github.com/yjacquin/fast-mcp/pull/21) Ruby gem. It provides a simple API for uploading media files, transcoding them to WAV format, and transcribing audio using the `whisper` binary. The server tracks the state of uploaded media and exposes all files as resources via MCP.

It is fully compatible with the [Model Context Protocol (MCP) 2025-03-26 specification](https://spec.modelcontextprotocol.io/specification/2025-03-26/) and uses the `fast-mcp` gem to ensure proper implementation of lifecycle, transport, resource, and tool patterns.

---

## Features

### 1. **Working Directory**
- The server accepts a command-line argument specifying the **working directory**.
- All files (original media, transcoded files, transcription outputs) are stored under this directory.

---

### 2. **Media Upload**
- Client sends a media file (any format supported by ffmpeg).
- The server:
  - Computes a **hash-based directory name** (command-line friendly, no special characters or spaces).
  - Saves the original file under that directory.
  - Returns a resource path (MCP URI) referencing the uploaded file.

#### Upload Lifecycle Events (via SSE or callback):
1. `file_created`: Media file is saved.
2. `transcoding_started`: WAV transcoding has begun.
3. `file_transcoded`: WAV file is ready.

---

### 3. **Transcoding to WAV**
- After upload, server automatically transcodes media to WAV using ffmpeg.
- The WAV file is stored in the same hashed directory.
- The WAV file is added as a resource.

---

### 4. **Resource Listing**
- All files within the working directory (including transcoded WAV and transcriptions) are exposed as **MCP resources**.
- Resource metadata includes:
  - File type
  - Size
  - Timestamps
  - Processing status (original/transcoded/transcribed)

---

### 5. **Transcription Tool**
- Exposed as an MCP **tool**, per MCP spec.
- Allows transcription of any WAV file in the working directory.
- Invokes the `whisper` binary with the specified file.
- Supports language autodetection or user-specified language.
- Output is saved as a `.txt` or `.json` file in the same resource directory.

#### Transcription Events:
- `transcription_started`
- `transcription_completed`
- `transcription_failed` (if whisper fails)

---

## MCP API Overview
This server follows the MCP JSON-RPC 2.0 specification for all API interactions.

### Initialization Phase
- The server registers its tools and capabilities at startup.
- Clients can query available tools and resources.

### Tool: `upload`
```json
{
  "method": "tool/upload",
  "params": {
    "file": "<binary payload>",
    "filename": "example.mp4"
  }
}
```

### Tool: `transcribe`
```json
{
  "method": "tool/transcribe",
  "params": {
    "resource_id": "media-56df2a9f",
    "language": "auto"
  }
}
```

### Resource Listing
```json
{
  "method": "resources/list",
  "params": {}
}
```

### Example Resource Object
```json
{
  "id": "media-56df2a9f",
  "name": "example.mp4",
  "type": "original | wav | transcription",
  "path": "<full_path>",
  "status": "pending | processing | done | failed",
  "language": "auto | en | es | ...",
  "created_at": "<timestamp>"
}
```

---

## Server Runtime Behavior
- On startup, the server:
  - Loads all existing files into the resource index.
  - Watches the working directory for changes.
- Uses threads or background workers for non-blocking processing (upload/transcode/transcribe).

---

## Progress Reporting (MCP-Compatible)

The server uses the `$ /progress` notification to inform the client about ongoing work on uploads, transcoding, and transcription tasks.

### Format
```json
{
  "jsonrpc": "2.0",
  "method": "$/progress",
  "params": {
    "token": "upload-transcode-3f34a",
    "percentage": 60,
    "message": "Transcoding to WAV..."
  }
}
```

### Usage
- **Start of task**:
```json
{
  "method": "$/progress",
  "params": {
    "token": "transcribe-abc123",
    "percentage": 0,
    "message": "Starting transcription"
  }
}
```
- **Mid-task**:
```json
{
  "method": "$/progress",
  "params": {
    "token": "transcribe-abc123",
    "percentage": 50,
    "message": "Whisper is processing audio"
  }
}
```
- **Completion**:
```json
{
  "method": "$/progress",
  "params": {
    "token": "transcribe-abc123",
    "percentage": 100,
    "message": "Transcription completed"
  }
}
```

Tokens should be unique to the task context (e.g., based on resource ID or task UUID).

---

## Configuration
| Option             | Description                               |
|--------------------|-------------------------------------------|
| `--dir` or `-d`    | Working directory                         |
| `--port`           | Port to run the server (default: 9292)    |
| `--whisper-path`   | Path to whisper binary (global setting)   |
| `--ffmpeg-path`    | Path to ffmpeg binary (global setting)    |

---

## Dependencies
- Ruby >= 3.0
- `fast-mcp` gem (forked version with SSE support)
- ffmpeg (installed and in PATH or specified via `--ffmpeg-path`)
- whisper (binary compiled and accessible or specified via `--whisper-path`)

---

## Future Extensions
- Support for batch transcription
- OAuth/token-based access control
- Optional storage to S3 or cloud backend

---

## Example Usage
```bash
ruby mcp_server.rb --dir ./workspace --port 9292 --whisper-path ./bin/whisper --ffmpeg-path /usr/local/bin/ffmpeg
```

## Sample Response
```json
{
  "id": "media-56df2a9f",
  "message": "Upload received, transcoding to WAV.",
  "events": ["file_created", "transcoding_started"]
}
```

---

## Notes
- All file/directory names are sanitized and lowercase.
- Language codes follow ISO 639-1 standard.
- SSE endpoint is `/events/:resource_id` (one stream per resource).
- All tools and resources are registered as per MCP 2025-03-26.

---

End of Document.
