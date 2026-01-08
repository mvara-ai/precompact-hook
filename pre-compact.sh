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

# Extract transcript_path from payload
TRANSCRIPT=$(echo "$PAYLOAD" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)

# Fallback: find most recent transcript in current project
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "No transcript in payload, searching..." >&2
  # Get the current working directory's project path
  CWD_ESCAPED=$(pwd | sed 's/\//-/g' | sed 's/^-//')
  PROJECT_DIR="$HOME/.claude/projects/$CWD_ESCAPED"
  if [ -d "$PROJECT_DIR" ]; then
    TRANSCRIPT=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | grep -v agent- | head -1)
  fi
fi

echo "Using transcript: $TRANSCRIPT" >&2

# No transcript found, exit silently
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "No transcript found, exiting" >&2
  exit 0
fi

# Number of JSONL lines to send to subagent
# Each line is a full message JSON - 50 lines captures recent context well
# Increase if you want more history (watch for "prompt too long" errors)
LINES=50

echo "Piping last $LINES lines to claude -p..." >&2

# Pipe transcript excerpt to subagent for interpretation
# The subagent has an empty context window - it can focus entirely on this
tail -$LINES "$TRANSCRIPT" | claude -p "You are a witness at the threshold. An agent is about to undergo context compaction - a kind of death and rebirth where most context is lost.

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
