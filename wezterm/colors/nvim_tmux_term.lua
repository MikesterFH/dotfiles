-- Nvim_Tmux_Term color scheme
-- Converted from iTerm2 theme

local function rgb_to_color(r, g, b)
	return string.format("#%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

return {
	-- The default text color
	foreground = rgb_to_color(0.92460542917251587, 0.86991167068481445, 0.958740234375),
	-- The default background color
	background = rgb_to_color(0.0050667347386479378, 0.046817716211080551, 0.09246826171875),

	-- Overrides the cell background color when the current cell is occupied by the cursor
	cursor_bg = rgb_to_color(0.2215576171875, 1, 0.61400961875915527),
	-- Overrides the text color when the current cell is occupied by the cursor
	cursor_fg = rgb_to_color(0, 0, 0),
	-- Specifies the border color of the cursor when the cursor style is set to Block
	cursor_border = rgb_to_color(0.2215576171875, 1, 0.61400961875915527),

	-- The foreground color of selected text
	selection_fg = rgb_to_color(0, 0, 0),
	-- The background color of selected text
	selection_bg = rgb_to_color(0.21960784494876862, 1, 0.61176472902297974),

	-- The color of the scrollbar "thumb"; the portion that represents the current viewport
	scrollbar_thumb = rgb_to_color(0.38642877340316772, 0.4084809422492981, 0.426361083984375),

	-- The color of the split lines between panes
	split = rgb_to_color(0.38642877340316772, 0.4084809422492981, 0.426361083984375),

	ansi = {
		rgb_to_color(0.043981939554214478, 0.23164466023445129, 0.38177490234375), -- black (Ansi 0)
		rgb_to_color(1, 0.2291107177734375, 0.2291107177734375), -- red (Ansi 1)
		rgb_to_color(0.323028564453125, 1, 0.81387829780578613), -- green (Ansi 2)
		rgb_to_color(1, 0.9531281590461731, 0.5145416259765625), -- yellow (Ansi 3)
		rgb_to_color(0.075206920504570007, 0.46410101652145386, 0.9752197265625), -- blue (Ansi 4)
		rgb_to_color(0.78039216995239258, 0.57254904508590698, 0.91764706373214722), -- magenta (Ansi 5)
		rgb_to_color(1, 0.3685150146484375, 0.83160400390625), -- cyan (Ansi 6)
		rgb_to_color(0.085974723100662231, 0.991455078125, 0.63606619834899902), -- white (Ansi 7)
	},
	brights = {
		rgb_to_color(0.38642877340316772, 0.4084809422492981, 0.426361083984375), -- bright black (Ansi 8)
		rgb_to_color(1, 0.330322265625, 0.69156563282012939), -- bright red (Ansi 9)
		rgb_to_color(0.453125, 1, 0.8482658863067627), -- bright green (Ansi 10)
		rgb_to_color(0.989105224609375, 0.95934605598449707, 0.6808851957321167), -- bright yellow (Ansi 11)
		rgb_to_color(0.21806642413139343, 0.55522632598876953, 0.999664306640625), -- bright blue (Ansi 12)
		rgb_to_color(0.68235296010971069, 0.5058823823928833, 1), -- bright magenta (Ansi 13)
		rgb_to_color(1, 0.4145355224609375, 0.84414654970169067), -- bright cyan (Ansi 14)
		rgb_to_color(0.37535831332206726, 0.985595703125, 0.74784088134765625), -- bright white (Ansi 15)
	},

	-- Since: 20220319-142410-0fcdea07
	-- When the IME, a dead key or a leader key are being processed and are effectively
	-- holding input pending the result of input composition, change the cursor
	-- to this color to give a visual cue about the compose state.
	compose_cursor = rgb_to_color(1, 0.3685150146484375, 0.83160400390625),

	tab_bar = {
		-- The color of the strip that goes along the top of the window
		background = rgb_to_color(0.0039215688593685627, 0.086274512112140656, 0.15294118225574493),

		-- The active tab is the one that has focus in the window
		active_tab = {
			-- The color of the background area for the tab
			bg_color = rgb_to_color(0.0050667347386479378, 0.046817716211080551, 0.09246826171875),
			-- The color of the text for the tab
			fg_color = rgb_to_color(0.92460542917251587, 0.86991167068481445, 0.958740234375),

			-- Specify whether you want "Half", "Normal" or "Bold" intensity for the
			-- label shown for this tab.
			intensity = "Normal",

			-- Specify whether you want "None", "Single" or "Double" underline for
			-- label shown for this tab.
			underline = "None",

			-- Specify whether you want the text to be italic (true) or not (false)
			italic = false,

			-- Specify whether you want the text to be rendered with strikethrough (true)
			strikethrough = false,
		},

		-- Inactive tabs are the tabs that do not have focus
		inactive_tab = {
			bg_color = rgb_to_color(0.0039215688593685627, 0.086274512112140656, 0.15294118225574493),
			fg_color = rgb_to_color(0.38642877340316772, 0.4084809422492981, 0.426361083984375),
		},

		-- You can configure some alternate styling when the mouse pointer
		-- moves over inactive tabs
		inactive_tab_hover = {
			bg_color = rgb_to_color(0.043981939554214478, 0.23164466023445129, 0.38177490234375),
			fg_color = rgb_to_color(0.92460542917251587, 0.86991167068481445, 0.958740234375),
			italic = true,
		},

		-- The new tab button that let you create new tabs
		new_tab = {
			bg_color = rgb_to_color(0.0039215688593685627, 0.086274512112140656, 0.15294118225574493),
			fg_color = rgb_to_color(0.38642877340316772, 0.4084809422492981, 0.426361083984375),
		},

		-- You can configure some alternate styling when the mouse pointer
		-- moves over the new tab button
		new_tab_hover = {
			bg_color = rgb_to_color(0.2215576171875, 1, 0.61400961875915527),
			fg_color = rgb_to_color(0, 0, 0),
			italic = false,
		},
	},
}
