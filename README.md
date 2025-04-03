
# WRITIN MCP SERVER with Claude Code
if you ask claude to write you a tool that is similar to example with prompt below - it usually cost $0,01-$0,02 (300 - 400 lines of ruby)

```
> READ _ref/fast-mcp/examples/save_to_markdown_file.rb and create _ref/fast-mcp/examples/filesystem_operations.rb in the same style with:
 - resources that can: read file, list directory content, list the whole tree of directory
 - tool that can write to the file (create / overwrite)
 - tool that can delete the file
 - tool that can apply patch
 It takes directory it can work as parameter (and we ensure that no edits can outside this directory)
 We should always return and take relative paths

 # ...

 > /cost
   ⎿  Total cost:            $0.0816
   ⎿  Total duration (API):  50.4s
   ⎿  Total duration (wall): 4m 35.1s
   ⎿  Total code changes:    338 lines added, 0 lines removed
 ```
