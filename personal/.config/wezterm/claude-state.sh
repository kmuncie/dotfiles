#!/bin/sh
# ============================================================================
# Claude Code hook: report session state to WezTerm
# ============================================================================
# Usage: claude-state.sh working|waiting|done|clear
#
# Sets the WezTerm user var `claude_state` on the pane that runs Claude Code.
# wezterm.lua reads it in `format-tab-title` to show a status icon per tab.
#
# Hooks run without a controlling terminal, so /dev/tty is not available.
# Instead, walk up the process tree to the first ancestor that has a TTY
# (the `claude` process) and write the escape sequence to that device.

# Only act when running directly in WezTerm (not in tmux or other terminals)
[ "$TERM_PROGRAM" = "WezTerm" ] || exit 0

state="$1"
if [ "$state" = "clear" ]; then
   state=""
fi

pid=$$
tty=""
while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
   tty=$(ps -o tty= -p "$pid" | tr -d ' ')
   if [ -n "$tty" ] && [ "$tty" != "??" ]; then
      break
   fi
   tty=""
   pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done

[ -n "$tty" ] || exit 0

# OSC 1337 SetUserVar: the value must be base64 encoded
printf '\033]1337;SetUserVar=claude_state=%s\007' "$(printf '%s' "$state" | base64)" \
   > "/dev/$tty" 2>/dev/null

exit 0
