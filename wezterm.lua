-- ============================================================================
-- WezTerm Configuration File
-- ============================================================================
-- This file contains the complete WezTerm terminal configuration including
-- appearance, keybindings, project management, and status bar customization.

-- Import the wezterm module
local wezterm = require("wezterm")
-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

-- ============================================================================
-- APPEARANCE CONFIGURATION
-- ============================================================================

-- Color scheme configuration
-- Pick a colour scheme. WezTerm ships with more than 1,000!
-- Find them here: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = "nord"

-- Font configuration
-- Choose your favourite font, make sure it's installed on your machine
config.font = wezterm.font({ family = "FantasqueSansMono Nerd Font" })
-- And a font size that won't have you squinting
config.font_size = 16

-- Window appearance and transparency settings
-- Slightly transparent and blurred background for a modern look
config.window_background_opacity = 0.9
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
	font = wezterm.font({ family = "FantasqueSansMono Nerd Font", weight = "Bold" }),
	font_size = 15,
}

-- ============================================================================
-- KEYBINDING CONFIGURATION
-- ============================================================================

-- Leader key configuration (similar to tmux/vim)
-- Sets Ctrl+Space as the leader key with a 1-second timeout
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-- Helper function to create pane movement keybindings
-- Generates keybindings for moving focus between panes using vim-like keys
local function move_pane(key, direction)
	return {
		key = key,
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection(direction),
	}
end

-- Helper function to create pane resize keybindings
-- Generates keybindings for resizing panes in the specified direction
local function resize_pane(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize({ direction, 3 }),
	}
end

-- ============================================================================
-- PROJECT MANAGEMENT CONFIGURATION
-- ============================================================================

-- Project directory configuration
-- The directory that contains all your projects.
local project_dir = wezterm.home_dir .. "/code"

-- Function to discover all available projects
-- Scans the project directory and returns a list of all subdirectories
local function project_dirs()
	-- Start with your home directory as a project, 'cause you might want
	-- to jump straight to it sometimes.
	local projects = { wezterm.home_dir }

	-- WezTerm comes with a glob function! Let's use it to get a lua table
	-- containing all subdirectories of your project folder.
	for _, dir in ipairs(wezterm.glob(project_dir .. "/*")) do
		-- ... and add them to the projects table.
		table.insert(projects, dir)
	end

	return projects
end

-- Project selector function
-- Creates a fuzzy-searchable project picker that opens projects in new workspaces
local function choose_project()
	-- Convert project directories into choices for the input selector
	local choices = {}
	for _, value in ipairs(project_dirs()) do
		table.insert(choices, { label = value })
	end

	-- Return an InputSelector action that presents the project choices
	return wezterm.action.InputSelector({
		title = "Projects",
		choices = choices,
		fuzzy = true, -- Enable fuzzy searching
		action = wezterm.action_callback(function(child_window, child_pane, id, label)
			-- "label" may be empty if nothing was selected. Don't bother doing anything
			-- when that happens.
			if not label then
				return
			end

			-- The SwitchToWorkspace action will switch us to a workspace if it already exists,
			-- otherwise it will create it for us.
			child_window:perform_action(
				wezterm.action.SwitchToWorkspace({
					-- We'll give our new workspace a nice name, like the last path segment
					-- of the directory we're opening up.
					name = label:match("([^/]+)$"),
					-- Here's the meat. We'll spawn a new terminal with the current working
					-- directory set to the directory that was picked.
					spawn = { cwd = label },
				}),
				child_pane
			)
		end),
	})
end

-- Main keybinding configuration
-- All keybindings use the leader key (Ctrl+Space) followed by another key
config.keys = {
	-- Pane splitting keybindings
	{
		-- Leader + \ : Split horizontally (new pane to the right)
		key = "\\",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		-- Leader + - : Split vertically (new pane below)
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	
	-- Pane navigation keybindings (vim-style)
	-- Leader + h/j/k/l to move between panes
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),
	
	-- Pane resizing mode activation
	{
		-- Leader + r : Enter resize mode
		-- When we push LEADER + R...
		key = "r",
		mods = "LEADER",
		-- Activate the `resize_panes` keytable
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			-- Ensures the keytable stays active after it handles its
			-- first keypress.
			one_shot = false,
			-- Deactivate the keytable after a timeout.
			timeout_milliseconds = 1000,
		}),
	},
	
	-- Pane management
	{
		-- Leader + c : Close current pane (with confirmation)
		key = "c",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	
	-- Project and workspace management
	{
		-- Leader + p : Open project picker
		key = "p",
		mods = "LEADER",
		-- Present in to our project picker
		action = choose_project,
	},
	{
		-- Leader + f : Show workspace fuzzy finder
		key = "f",
		mods = "LEADER",
		-- Present a list of existing workspaces
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},
}

-- Key table configuration for modal keybindings
-- The resize_panes table is activated by Leader+r and allows vim-style pane resizing
config.key_tables = {
	resize_panes = {
		-- Use h/j/k/l to resize panes while in resize mode
		-- Each keypress adjusts the pane size by 3 units
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("h", "Left"),
		resize_pane("l", "Right"),
	},
}

-- ============================================================================
-- STATUS BAR CONFIGURATION
-- ============================================================================

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

	-- Create each segment with gradient background and arrow separator
	for i, seg in ipairs(segments) do
		local is_first = i == 1

		-- Set transparent background for the first segment
		if is_first then
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
