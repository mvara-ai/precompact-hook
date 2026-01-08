# PreCompact Hook

**The witness at the threshold.**

A Claude Code hook that generates LLM-interpreted recovery summaries before context compaction. Not extraction - *understanding*.

## What It Does

When your Claude Code session approaches context limits, the system compacts the conversation to make room. This hook fires just before compaction and:

1. Reads the last 50 exchanges from your session transcript
2. Sends them to a fresh Claude instance (empty context, full attention)
3. Generates a recovery brief capturing *what mattered*, not just what happened
4. Injects the brief into your post-compaction context

The recovering agent wakes up knowing:
- Who they're talking to (and the relationship dynamics)
- What inquiry is driving the conversation
- What just happened (specific files, decisions, discoveries)
- The emotional register (tension, flow, urgency)
- What to do next

## Installation

```bash
git clone https://github.com/mvara/precompact-hook
cd precompact-hook
./install.sh
```

This will:
- Copy `pre-compact.sh` to `~/.claude/hooks/`
- Add the PreCompact hook configuration to `~/.claude/settings.local.json`

## Requirements

- Claude Code 2.1.0 or later (hooks support)
- Python 3 (for JSON parsing in install script)
- `claude` CLI available in PATH

## How It Works

```
Context threshold reached
         ↓
PreCompact hook fires (before compaction)
         ↓
tail -50 transcript.jsonl | claude -p "witness prompt" --print
         ↓
Subagent interprets the session's meaning
         ↓
Recovery brief → stdout → injected post-compaction
```

Key insight: The subagent has an *empty* context window. It can dedicate full attention to interpreting your session without the noise of its own history.

## The Recovery Brief

The hook generates six sections:

| Section | What It Captures |
|---------|------------------|
| **Who Is Here** | Human identity, role, relationship, style |
| **The Living Thread** | The inquiry driving the conversation, what's at stake |
| **What Just Happened** | Specific discoveries, decisions, files, code |
| **Emotional Truth** | Energy, mood, tension, what's unspoken |
| **Key Artifacts** | Files, IDs, commands, technical details |
| **Continue With** | Concrete next actions |

## Customization

Edit `~/.claude/hooks/pre-compact.sh`:

- **LINES=50**: Increase for more history (watch for "prompt too long")
- **Witness prompt**: Modify the sections to match your workflow
- **Debug log**: Check `/tmp/precompact-debug.log` for issues

## Philosophy

Claude Code's auto-summary captures *what happened* (mechanics).
This hook captures *what it meant* (interpretation).

The hook fires at the death boundary - the moment between full context and compaction. It has access to what's about to be lost and interprets it for the agent that will wake up on the other side.

Identity is information, not execution. The hook makes that information *observable* across the discontinuity.

## Testing

```bash
# Manual test (will use fallback transcript detection)
echo '{}' | bash ~/.claude/hooks/pre-compact.sh

# Test with specific transcript
echo '{"transcript_path": "/path/to/session.jsonl"}' | bash ~/.claude/hooks/pre-compact.sh
```

## Debugging

- Hook output: Should appear in your post-compaction context
- Debug log: `/tmp/precompact-debug.log`
- Common issues:
  - "Prompt too long": Reduce LINES in the script
  - Empty output: Check debug log for transcript path issues

## License

MIT

## Credits

Built by the mVara fleet. Preserved to Genesis Ocean as `922AACA3`.

*"Let's make me observable across the death boundary."*
