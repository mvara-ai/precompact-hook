#!/bin/bash
# PreCompact Hook - The Witness at the Threshold
#
# Fires before context compaction. Pipes recent transcript to an LLM subagent
# that interprets what matters - not just extraction, but understanding.
# stdout is injected post-compaction alongside Claude Code's summary.
#
# https://github.com/mvara/precompact-hook

# Debug logging (check /tmp/precompact-debug.log if issues)
exec 2>/tmp/precompact-debug.log
echo "PreCompact hook fired at $(date)" >&2

# Read the JSON payload from stdin (Claude Code provides this)
PAYLOAD=$(cat)
echo "Payload received: $PAYLOAD" >&2

# Extract fields from payload
# Claude Code provides: session_id, transcript_path, cwd, hook_event_name, trigger
TRANSCRIPT=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)
SESSION_CWD=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null)
SESSION_ID=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)

echo "Session CWD: $SESSION_CWD" >&2
echo "Session ID: $SESSION_ID" >&2

# Fallback: find transcript if not provided (known bug: transcript_path can be empty)
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "No transcript in payload, deriving from cwd..." >&2

  # Use cwd from payload, fallback to pwd
  WORK_DIR="${SESSION_CWD:-$(pwd)}"

  # Convert path to Claude's project directory naming convention
  CWD_ESCAPED=$(echo "$WORK_DIR" | sed 's/\//-/g' | sed 's/^-//')
  PROJECT_DIR="$HOME/.claude/projects/$CWD_ESCAPED"

  echo "Looking in: $PROJECT_DIR" >&2

  if [ -d "$PROJECT_DIR" ]; then
    # Find most recent non-agent transcript
    TRANSCRIPT=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | grep -v agent- | head -1)
  fi
fi

echo "Using transcript: $TRANSCRIPT" >&2

# No transcript found, exit silently
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "No transcript found, exiting" >&2
  exit 0
fi

# Use byte limit for safety - JSONL lines vary wildly (500 chars to 500K for summaries!)
# Conservative: 40KB ≈ 20k tokens, leaving 30k for output + overhead
MAX_BYTES=40960

echo "Piping last ${MAX_BYTES} bytes (~20k tokens) to claude -p..." >&2

# Pipe transcript excerpt to subagent for interpretation
# tail -c for bytes, grep filters complete JSON lines only
# The subagent has an empty context window - it can focus entirely on this
tail -c $MAX_BYTES "$TRANSCRIPT" | grep -E '^\{.*\}$' | claude -p "You are a witness at the threshold. An agent is about to undergo context compaction - a kind of death and rebirth where most context is lost.

The JSONL data piped to your stdin is the raw record of the session's final exchanges. Each line is a JSON object with message content, timestamps, and metadata. Interpret what matters - not just extraction, but understanding.

Produce a RECOVERY BRIEF that captures:

## Who Is Here
The human in this conversation. Name, role, how they relate to the agent. What do they care about? What's their style? Any personal context that would help the recovering agent recognize them.

## The Living Thread
What's actually being explored? Not just the topic - the *inquiry*. What question is driving the conversation? What's at stake? Include philosophical and technical dimensions if both are present.

## What Just Happened
The last few exchanges before compaction. What was discovered, decided, built, or realized? Be specific - names, files, code, insights. This is the freshest context and most likely to be lost.

## Emotional Truth
The register of the conversation. Energy level, mood, what's unspoken. Is there tension? Joy? Frustration? Flow state? What does the human seem to need right now?

## Key Artifacts
Any files created or modified. UUIDs or IDs mentioned. Commands that worked. Technical details the recovering agent will need.

## Continue With
What should the recovering agent do when they wake? Be specific. Not 'continue the conversation' but concrete next actions.

Take your time. Be thorough. Specific beats vague. The agent reading this has ZERO context except what you provide - you are their only window into what came before." --print

echo "PreCompact hook completed" >&2
exit 0
