-- ============================================================================
-- WezTerm Configuration File
-- ============================================================================
-- This file contains the complete WezTerm terminal configuration including
-- appearance, keybindings, project management, and status bar customization.

-- Import the wezterm module
local wezterm = require("wezterm")
local act = wezterm.action
-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

-- Catppuccin Mocha palette, shared by the color scheme and the tab bar
local palette = require("catppuccin-mocha")

-- Catppuccin Mocha accent colors used for tab status and per-tab colors
local accents = {
   blue = "#89b4fa",
   green = "#a6e3a1",
   peach = "#fab387",
   red = "#f38ba8",
   yellow = "#f9e2af",
   mauve = "#cba6f7",
   teal = "#94e2d5",
   pink = "#f5c2e7",
   sky = "#89dceb",
   lavender = "#b4befe",
   crust = "#11111b",
}

-- ============================================================================
-- APPEARANCE CONFIGURATION
-- ============================================================================

-- Color scheme configuration
-- Pick a colour scheme. WezTerm ships with more than 1,000!
-- Find them here: https://wezfurlong.org/wezterm/colorschemes/index.html
-- config.color_scheme = "nord"
config.colors = palette

-- Use the WebGpu renderer (Metal on macOS) for best performance
config.front_end = "WebGpu"

-- Font configuration
-- Choose your favourite font, make sure it's installed on your machine
config.font = wezterm.font({ family = "FantasqueSansM Nerd Font Mono" })
-- And a font size that won't have you squinting
config.font_size = 16

-- Window appearance and transparency settings
-- Slightly transparent and blurred background for a modern look
config.window_background_opacity = 0.8
config.macos_window_background_blur = 30

-- Window decoration settings
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = "RESIZE"

-- Tab bar and window frame font configuration
-- Sets the font for the window frame (tab bar)
config.window_frame = {
   -- Using the same font family as terminal but with bold weight
   -- for better visibility in the tab bar
   font = wezterm.font({ family = "FantasqueSansM Nerd Font", weight = "Bold" }),
   font_size = 12,
}

-- The default (16 cells) cuts off Claude Code session titles
config.tab_max_width = 40

-- ============================================================================
-- PROJECT MANAGEMENT CONFIGURATION
-- ============================================================================

-- Project directory configuration
-- The directory that contains all your projects. Projects are grouped in
-- buckets one level down (e.g. ~/Code/BETHEL/<repo>, ~/Code/PERSONAL/<repo>).
local project_dir = wezterm.home_dir .. "/Code"

-- Returns true when the path is a directory. wezterm.glob also returns
-- files, and read_dir fails on anything that is not a directory.
local function is_dir(path)
   return (pcall(wezterm.read_dir, path))
end

-- Function to discover all available projects
-- Returns each bucket in the project directory, followed by its subdirectories
local function project_dirs()
   -- Start with your home directory as a project, 'cause you might want
   -- to jump straight to it sometimes.
   local projects = { wezterm.home_dir }

   -- WezTerm comes with a glob function! Let's use it to get a lua table
   -- containing the buckets, then the repos inside each bucket.
   for _, bucket in ipairs(wezterm.glob(project_dir .. "/*")) do
      if is_dir(bucket) then
         -- The bucket itself is a choice too, so you can jump to it
         table.insert(projects, bucket)

         for _, dir in ipairs(wezterm.glob(bucket .. "/*")) do
            if is_dir(dir) then
               table.insert(projects, dir)
            end
         end
      end
   end

   return projects
end

-- Project selector function
-- Creates a fuzzy-searchable project picker that opens projects in new tabs
local function choose_project()
   -- Convert project directories into choices for the input selector. The
   -- label is the path relative to the project directory ("BETHEL/<repo>"),
   -- so you can filter by bucket. The id holds the full path.
   local choices = {}
   for _, value in ipairs(project_dirs()) do
      local label = value
      if value:sub(1, #project_dir + 1) == project_dir .. "/" then
         label = value:sub(#project_dir + 2)
      elseif value == wezterm.home_dir then
         label = "~"
      end
      table.insert(choices, { id = value, label = label })
   end

   -- Return an InputSelector action that presents the project choices
   return act.InputSelector({
      title = "Projects",
      choices = choices,
      fuzzy = true, -- Enable fuzzy searching
      action = wezterm.action_callback(function(child_window, child_pane, id, label)
         -- "id" may be empty if nothing was selected. Don't bother doing anything
         -- when that happens.
         if not id then
            return
         end

         -- Open a new tab in the current window with the working directory set
         -- to the directory that was picked. A new tab (not a new workspace)
         -- keeps all other tabs visible.
         child_window:perform_action(
            act.SpawnCommandInNewTab({ cwd = id }),
            child_pane
         )
      end),
   })
end

-- ============================================================================
-- KEYBINDING CONFIGURATION
-- ============================================================================
-- Every binding carries a `desc`. The descriptions feed the cheatsheet
-- (Leader + ?) and the leader hint in the status bar, so they stay in sync
-- with the real bindings. `desc` is stripped before the bindings are handed
-- to WezTerm.

-- Leader key configuration (similar to tmux/vim)
-- Sets Ctrl+Space as the leader key with a 1-second timeout
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-- Helper function to create pane movement keybindings
-- Generates keybindings for moving focus between panes using vim-like keys
local function move_pane(key, direction)
   return {
      key = key,
      mods = "LEADER",
      action = act.ActivatePaneDirection(direction),
      desc = "Focus pane " .. direction:lower(),
   }
end

-- Helper function to create pane resize keybindings
-- Generates keybindings for resizing panes in the specified direction
local function resize_pane(key, direction)
   return {
      key = key,
      action = act.AdjustPaneSize({ direction, 3 }),
      desc = "Resize pane " .. direction:lower(),
   }
end

-- Prompts for a tab title. An empty title clears it, so the tab falls back
-- to the automatic title (Claude Code session title or process ~ directory).
local rename_tab = act.PromptInputLine({
   description = "Tab title (leave empty to use the automatic title)",
   action = wezterm.action_callback(function(window, _, line)
      -- "line" is nil when the prompt was cancelled with Escape
      if line ~= nil then
         window:active_tab():set_title(line)
      end
   end),
})

-- The cheatsheet action is defined further down, after the key list it reads
local show_cheatsheet

-- Main keybinding configuration
-- All keybindings use the leader key (Ctrl+Space) followed by another key
local leader_keys = {
   -- Pane splitting keybindings
   {
      key = "\\",
      mods = "LEADER",
      action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
      desc = "Split pane right",
   },
   {
      key = "-",
      mods = "LEADER",
      action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
      desc = "Split pane down",
   },

   -- Pane navigation keybindings (vim-style)
   move_pane("h", "Left"),
   move_pane("j", "Down"),
   move_pane("k", "Up"),
   move_pane("l", "Right"),

   -- Pane resizing mode activation
   {
      key = "r",
      mods = "LEADER",
      -- Activate the `resize_panes` keytable
      action = act.ActivateKeyTable({
         name = "resize_panes",
         -- Ensures the keytable stays active after it handles its
         -- first keypress.
         one_shot = false,
         -- Deactivate the keytable after a timeout.
         timeout_milliseconds = 1000,
      }),
      desc = "Resize mode (then h/j/k/l)",
   },

   -- Pane management
   {
      key = "c",
      mods = "LEADER",
      action = act.CloseCurrentPane({ confirm = true }),
      desc = "Close pane",
   },

   -- Tab management
   {
      key = ",",
      mods = "LEADER",
      action = rename_tab,
      desc = "Rename tab",
   },
   {
      key = "n",
      mods = "LEADER",
      action = act.ActivateTabRelative(1),
      desc = "Next tab",
   },
   {
      key = "b",
      mods = "LEADER",
      action = act.ActivateTabRelative(-1),
      desc = "Previous tab",
   },

   -- Project and workspace management
   {
      key = "p",
      mods = "LEADER",
      action = wezterm.action_callback(function(window, pane)
         window:perform_action(choose_project(), pane)
      end),
      desc = "Project picker",
   },
   {
      key = "f",
      mods = "LEADER",
      action = act.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }),
      desc = "Find tab or workspace",
   },

   -- Help
   {
      key = "?",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function(window, pane)
         show_cheatsheet(window, pane)
      end),
      desc = "Key binding cheatsheet",
   },

   -- Press the leader twice to send Ctrl+Space to the running program
   {
      key = "Space",
      mods = "LEADER|CTRL",
      action = act.SendKey({ key = "Space", mods = "CTRL" }),
      desc = "Send Ctrl+Space to program",
   },
}

-- Leader + 1..9 : Jump to tab by number
for i = 1, 9 do
   table.insert(leader_keys, {
      key = tostring(i),
      mods = "LEADER",
      action = act.ActivateTab(i - 1),
      desc = "Go to tab " .. i,
   })
end

-- Key table configuration for modal keybindings
-- The resize_panes table is activated by Leader+r and allows vim-style pane resizing
local key_tables = {
   resize_panes = {
      -- Use h/j/k/l to resize panes while in resize mode
      -- Each keypress adjusts the pane size by 3 units
      resize_pane("h", "Left"),
      resize_pane("j", "Down"),
      resize_pane("k", "Up"),
      resize_pane("l", "Right"),
   },
}

-- WezTerm default bindings worth remembering. They are listed in the
-- cheatsheet only; WezTerm already binds them.
local default_keys = {
   { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain"), desc = "New tab" },
   { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = true }), desc = "Close tab" },
   { key = "f", mods = "CMD", action = act.Search("CurrentSelectionOrEmptyString"), desc = "Search scrollback" },
   { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackOnly"), desc = "Clear scrollback" },
   { key = "x", mods = "CTRL|SHIFT", action = act.ActivateCopyMode, desc = "Copy mode (vim keys)" },
   { key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette, desc = "Command palette" },
   { key = "Enter", mods = "ALT", action = act.ToggleFullScreen, desc = "Toggle full screen" },
}

-- Copies binding lists without the `desc` field, which WezTerm does not accept
local function strip_desc(bindings)
   local result = {}
   for _, binding in ipairs(bindings) do
      table.insert(result, { key = binding.key, mods = binding.mods, action = binding.action })
   end
   return result
end

config.keys = strip_desc(leader_keys)
config.key_tables = {}
for name, bindings in pairs(key_tables) do
   config.key_tables[name] = strip_desc(bindings)
end

-- ============================================================================
-- CHEATSHEET (Leader + ?)
-- ============================================================================

-- Turns a binding into a readable key label, e.g. "Ctrl+Space \" or "Cmd+T"
local function key_label(binding)
   local key = binding.key
   local mods = binding.mods or ""
   if mods:find("LEADER") then
      -- Shift is implied for "?" and Ctrl for the double-leader binding
      if binding.key == "Space" then
         return "Ctrl+Space Ctrl+Space"
      end
      return "Ctrl+Space " .. key
   end

   local parts = {}
   for _, mod in ipairs({ "CMD", "CTRL", "ALT", "SHIFT" }) do
      if mods:find(mod) then
         table.insert(parts, mod:sub(1, 1) .. mod:sub(2):lower())
      end
   end
   table.insert(parts, #key == 1 and key:upper() or key)
   return table.concat(parts, "+")
end

-- Shows every binding with its description in a fuzzy list. Selecting an
-- entry runs its action.
show_cheatsheet = function(window, pane)
   local entries = {}
   for _, binding in ipairs(leader_keys) do
      table.insert(entries, { label = key_label(binding), binding = binding })
   end
   for _, binding in ipairs(key_tables.resize_panes) do
      table.insert(entries, { label = "Ctrl+Space R " .. binding.key, binding = binding })
   end
   for _, binding in ipairs(default_keys) do
      table.insert(entries, { label = key_label(binding), binding = binding })
   end

   local choices = {}
   for i, entry in ipairs(entries) do
      table.insert(choices, {
         id = tostring(i),
         label = string.format("%-24s %s", entry.label, entry.binding.desc),
      })
   end

   window:perform_action(
      act.InputSelector({
         title = "Key bindings (type to filter, Enter runs it)",
         choices = choices,
         fuzzy = true,
         action = wezterm.action_callback(function(child_window, child_pane, id)
            if not id then
               return
            end
            child_window:perform_action(entries[tonumber(id)].binding.action, child_pane)
         end),
      }),
      pane
   )
end

-- ============================================================================
-- TAB TITLE CONFIGURATION
-- ============================================================================
-- Title priority:
--   1. A title set manually with Leader + ,
--   2. The Claude Code session title (Claude Code writes it to the pane title)
--   3. "process ~ directory"
--
-- Claude Code tabs always show a status icon. It comes from two signals:
--   * The `claude_state` user var, which Claude Code hooks set through
--     claude-state.sh. Only the hooks know when Claude waits for an answer
--     or a permission.
--   * The glyph Claude Code puts before its title: a spinner (◐ ◓ ◑ ◒) while
--     it works and ✳ when it is idle. The glyph stays correct when a turn
--     is interrupted with Esc, where no hook runs.
-- States: working = Claude is running, waiting = Claude needs an answer or
-- a permission, done = the turn finished and it is your turn, unknown = no
-- signal yet.

-- Status icon and color for each state
local claude_states = {
   working = { icon = "●", color = accents.blue },
   waiting = { icon = wezterm.nerdfonts.fa_exclamation_circle, color = accents.peach },
   done = { icon = "✓", color = accents.green },
   unknown = { icon = "○", color = "#6c7086" },
}

-- Glyph that Claude Code puts before its title when the session is idle
local CLAUDE_IDLE_GLYPH = "✳"

-- Colors for the per-tab marker, picked by a hash of the tab title
local marker_colors = {
   accents.blue,
   accents.green,
   accents.peach,
   accents.yellow,
   accents.teal,
   accents.pink,
   accents.sky,
   accents.lavender,
}

-- Extracts the last path segment from a URL or file path
local function basename(s)
   return (string.gsub(s, "(.*[/\\])(.*)", "%2"))
end

-- Returns the pane's working directory as a path, or "" when unknown
local function pane_cwd(pane)
   local cwd_uri = pane.current_working_dir
   if not cwd_uri then
      return ""
   end
   local dir = cwd_uri.file_path or tostring(cwd_uri)
   return (dir:gsub("/$", ""))
end

-- Claude Code puts a status glyph (spinner, ✳) before its title. The tab
-- shows its own status icon, so remove the glyph: any leading non-ASCII
-- characters followed by a space.
local function strip_leading_glyph(title)
   return (title:gsub("^[\128-\255]+%s+", ""))
end

-- Returns the state of a Claude Code pane from the hook state and the
-- title glyph. "waiting" comes only from the hooks, so it wins. Otherwise
-- the glyph decides, and the hook state is the fallback.
local function claude_status(pane)
   local hook_state = pane.user_vars.claude_state or ""
   if hook_state == "waiting" then
      return claude_states.waiting
   end

   local glyph = pane.title:match("^([\128-\255]+)%s")
   if glyph == CLAUDE_IDLE_GLYPH then
      return claude_states.done
   end
   if glyph then
      return claude_states.working
   end

   return claude_states[hook_state] or claude_states.unknown
end

-- Stable small hash of a string, used to pick a marker color
local function hash(s)
   local h = 0
   for i = 1, #s do
      h = (h * 31 + s:byte(i)) % 2147483647
   end
   return h
end

-- Tabs that rang the bell while in the background, keyed by tab ID.
-- Kept in wezterm.GLOBAL so the marks survive a configuration reload.
local function bell_tabs()
   return wezterm.GLOBAL.bell_tabs or {}
end

wezterm.on("bell", function(window, pane)
   local tab = pane:tab()
   if not tab or tab:tab_id() == window:active_tab():tab_id() then
      return
   end
   local tabs = bell_tabs()
   tabs[tostring(tab:tab_id())] = true
   wezterm.GLOBAL.bell_tabs = tabs
end)

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
   local pane = tab.active_pane
   local process_path = pane.foreground_process_name or ""
   local process = basename(process_path)
   local cwd = pane_cwd(pane)

   -- The native Claude Code install runs ~/.local/share/claude/versions/<version>,
   -- so the executable name is the version number, not "claude"
   local is_claude = process == "claude" or process_path:find("/claude/versions/", 1, true) ~= nil
   if is_claude then
      process = "claude"
   end

   -- Clear the bell mark once the tab is visited
   local tab_key = tostring(tab.tab_id)
   local tabs = bell_tabs()
   if tab.is_active and tabs[tab_key] then
      tabs[tab_key] = nil
      wezterm.GLOBAL.bell_tabs = tabs
   end
   local has_bell = tabs[tab_key] == true

   -- Pick the title by priority
   local title
   if tab.tab_title and #tab.tab_title > 0 then
      title = tab.tab_title
   elseif is_claude and strip_leading_glyph(pane.title) ~= "" then
      title = strip_leading_glyph(pane.title)
   else
      title = process
      if cwd ~= "" then
         title = title .. " ~ " .. basename(cwd)
      end
   end

   -- Claude Code worktrees live in <repo>/.claude/worktrees/<name>.
   -- Add the worktree name so parallel sessions in one repo differ.
   local worktree = cwd:match("/%.claude/worktrees/([^/]+)")
   if is_claude and worktree then
      title = title .. " ⎇ " .. worktree
   end

   -- Status icon for Claude Code tabs, or a bell mark for any tab
   local status = nil
   if is_claude then
      status = claude_status(pane)
   end
   if not status and has_bell then
      status = { icon = wezterm.nerdfonts.fa_bell, color = accents.yellow }
   end

   -- Leave room for " N ", the status icon, and padding
   local prefix_width = #tostring(tab.tab_index + 1) + (status and 4 or 2)
   title = wezterm.truncate_right(title, math.max(max_width - prefix_width - 1, 8))

   local marker_color = marker_colors[(hash(title) % #marker_colors) + 1]
   local elements = {}

   if tab.is_active then
      -- The active tab keeps its palette colors. The status icon gets a
      -- small block in its state color so it shows on the active background.
      local active = palette.tab_bar.active_tab
      table.insert(elements, { Text = " " .. (tab.tab_index + 1) .. " " })
      if status then
         table.insert(elements, { Background = { Color = status.color } })
         table.insert(elements, { Foreground = { Color = accents.crust } })
         table.insert(elements, { Text = " " .. status.icon .. " " })
         table.insert(elements, { Background = { Color = active.bg_color } })
         table.insert(elements, { Foreground = { Color = active.fg_color } })
      end
      table.insert(elements, { Text = " " .. title .. " " })
      return elements
   end

   -- A tab that waits for you gets a colored background so it stands out
   local needs_you = status
      and status ~= claude_states.working
      and status ~= claude_states.unknown
   if needs_you then
      table.insert(elements, { Background = { Color = status.color } })
      table.insert(elements, { Foreground = { Color = accents.crust } })
      table.insert(elements, { Text = " " .. (tab.tab_index + 1) .. " " .. status.icon .. " " })
      table.insert(elements, { Text = title .. " " })
      return elements
   end

   -- The tab number takes the tab's marker color
   table.insert(elements, { Foreground = { Color = marker_color } })
   table.insert(elements, { Text = " " .. (tab.tab_index + 1) .. " " })
   if status then
      table.insert(elements, { Foreground = { Color = status.color } })
      table.insert(elements, { Text = status.icon .. " " })
   end
   table.insert(elements, { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } })
   table.insert(elements, { Text = title .. " " })
   return elements
end)

-- ============================================================================
-- STATUS BAR CONFIGURATION
-- ============================================================================

-- Returns the hint for the active key mode, or nil when no mode is active.
-- Built from the binding descriptions, so it always matches the bindings.
local function key_mode_hint(window)
   local key_table = window:active_key_table()
   if key_table == "resize_panes" then
      return "RESIZE  h j k l"
   end
   if window:leader_is_active() then
      local keys = {}
      for _, binding in ipairs(leader_keys) do
         -- Tab numbers are summarized as "1-9" below
         if not binding.key:match("^%d$") and binding.key ~= "Space" then
            table.insert(keys, binding.key)
         end
      end
      return "LEADER  " .. table.concat(keys, " ") .. " 1-9"
   end
   return nil
end

-- Function to define what information appears in the right status bar
-- Returns an array of segments: workspace name, date/time, hostname
local function segments_for_right_status(window)
   return {
      window:active_workspace(), -- Current workspace name
      wezterm.strftime("%a %b %-d %H:%M"), -- Date and time (e.g., "Mon Jan 1 14:30")
      wezterm.hostname(), -- System hostname
   }
end

-- Status bar update event handler
-- Creates a gradient-styled status bar with workspace, time, and hostname info
wezterm.on("update-status", function(window, _)
   -- Unicode character for the arrow separator
   local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
   local segments = segments_for_right_status(window)

   -- Get current color scheme colors
   local color_scheme = window:effective_config().resolved_palette
   local bg = wezterm.color.parse(color_scheme.background)
   local fg = color_scheme.foreground

   -- Create gradient colors for the status bar segments
   -- Fixed gradient direction (assuming dark theme behavior)
   local gradient_to = bg
   local gradient_from = gradient_to:lighten(0.2)

   -- If you prefer light theme behavior, use this instead:
   -- local gradient_from = gradient_to:darken(0.2)

   -- Generate gradient colors for each segment
   local gradient = wezterm.color.gradient({
      orientation = "Horizontal",
      colors = { gradient_from, gradient_to },
   }, #segments)

   -- Build the formatted elements for the status bar
   local elements = {}

   -- Show the keys available in the active mode (leader or resize)
   local hint = key_mode_hint(window)
   if hint then
      table.insert(elements, { Background = { Color = "none" } })
      table.insert(elements, { Foreground = { Color = accents.peach } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
      table.insert(elements, { Background = { Color = accents.peach } })
      table.insert(elements, { Foreground = { Color = accents.crust } })
      table.insert(elements, { Text = " " .. hint .. " " })
   end

   -- Create each segment with gradient background and arrow separator
   for i, seg in ipairs(segments) do
      local is_first = i == 1

      -- Set transparent background for the first segment
      if is_first and not hint then
         table.insert(elements, { Background = { Color = "none" } })
      end
      -- Add the arrow separator with gradient color
      table.insert(elements, { Foreground = { Color = gradient[i] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })

      -- Add the segment text with foreground and background colors
      table.insert(elements, { Foreground = { Color = fg } })
      table.insert(elements, { Background = { Color = gradient[i] } })
      table.insert(elements, { Text = " " .. seg .. " " })
   end

   -- Apply the formatted elements to the right status bar
   window:set_right_status(wezterm.format(elements))
end)

-- ============================================================================
-- CONFIGURATION EXPORT
-- ============================================================================

-- Returns our config to be evaluated. We must always do this at the bottom of this file
return config
