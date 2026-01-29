local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- Check if current pane is running Neovim (using IS_NVIM user variable)
local function is_vim(pane)
  -- This is set by smart-splits.nvim plugin
  return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- Pass keys through to Neovim (smart-splits will handle it)
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'META' or 'CTRL' },
        }, pane)
      else
        -- Handle in Wezterm directly
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

function module.apply_to_config(config)
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

	config.keys = {
		-- ===== TAB MANAGEMENT =====
		{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
		{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

		-- ===== PANE MANAGEMENT =====
		-- Splitting
		{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- Smart-splits navigation with Neovim integration
		split_nav('move', 'h'),
		split_nav('move', 'j'),
		split_nav('move', 'k'),
		split_nav('move', 'l'),

		-- Smart-splits resizing with Neovim integration
		split_nav('resize', 'h'),
		split_nav('resize', 'j'),
		split_nav('resize', 'k'),
		split_nav('resize', 'l'),

		-- Navigation (Leader-basiert für weniger Konflikte)
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

		-- Pane schließen
		{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

		-- Pane-Größe anpassen
		-- Kontinuierliche Pane-Größenanpassung aktivieren
		{
			key = "H",
			mods = "LEADER|SHIFT",
			action = act.Multiple({
				act.AdjustPaneSize({ "Left", 5 }),
				act.ActivateKeyTable({
					name = "resize_pane_continuous",
					one_shot = false,
					timeout_milliseconds = 3000,
					replace_current = false,
				}),
			}),
		},
		{
			key = "L",
			mods = "LEADER|SHIFT",
			action = act.Multiple({
				act.AdjustPaneSize({ "Right", 5 }),
				act.ActivateKeyTable({
					name = "resize_pane_continuous",
					one_shot = false,
					timeout_milliseconds = 3000,
					replace_current = false,
				}),
			}),
		},
		{
			key = "K",
			mods = "LEADER|SHIFT",
			action = act.Multiple({
				act.AdjustPaneSize({ "Up", 5 }),
				act.ActivateKeyTable({
					name = "resize_pane_continuous",
					one_shot = false,
					timeout_milliseconds = 3000,
					replace_current = false,
				}),
			}),
		},
		{
			key = "J",
			mods = "LEADER|SHIFT",
			action = act.Multiple({
				act.AdjustPaneSize({ "Down", 5 }),
				act.ActivateKeyTable({
					name = "resize_pane_continuous",
					one_shot = false,
					timeout_milliseconds = 3000,
					replace_current = false,
				}),
			}),
		},

		-- Zoom Pane toggle
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

		-- ===== COPY/PASTE MODE =====
		{ key = "v", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "p", mods = "LEADER", action = act.PasteFrom("Clipboard") },

		-- ===== QUICK COMMANDS =====
		{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
		{ key = "d", mods = "LEADER", action = act.ShowDebugOverlay },

		-- Command Palette
		{ key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

		-- Quick Select (URL/Hash picking)
		{ key = "u", mods = "LEADER", action = act.QuickSelect },

		-- Launch Menu
		{ key = "p",
		  mods = "CTRL|SHIFT",
			action = wezterm.action.ShowLauncherArgs {
				flags = "FUZZY|LAUNCH_MENU_ITEMS",
      }
    },

    -- Shortcut Menu
    {
      key = "K",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ShowLauncherArgs {
        flags = "FUZZY|KEY_ASSIGNMENTS",
      },
    }
	}
end

return module
