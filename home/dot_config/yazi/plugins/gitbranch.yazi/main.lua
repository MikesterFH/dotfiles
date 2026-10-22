--- @since 26.8.15

-- Shows `<branch>` plus `*` when the working tree is dirty in the header,
-- while the cwd is inside a git repository.

local M = {}

local set = ya.sync(function(st, cwd, text)
	if tostring(cx.active.current.cwd) == cwd then
		st.text = text
		ui.render()
	end
end)

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

function M:setup()
	local st = self

	Header:children_add(function()
		if not st.text or st.text == "" then
			return ""
		end
		return ui.Line { ui.Span(" " .. st.text):fg("magenta") }
	end, 3000, Header.LEFT)

	local function refresh()
		st.text = ""
		ya.emit("plugin", { "gitbranch" })
	end
	ps.sub("cd", refresh)
	ps.sub("tab", refresh)
end

function M:entry()
	local cwd = get_cwd()
	if cwd == "" then
		return
	end

	local out = Command("git")
		:cwd(cwd)
		:arg({ "--no-optional-locks", "status", "--porcelain=v2", "--branch" })
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:output()
	if not out or not out.status.success then
		return set(cwd, "")
	end

	local branch, dirty = nil, false
	for line in out.stdout:gmatch("[^\r\n]+") do
		if line:sub(1, 1) ~= "#" then
			dirty = true
			break
		end
		branch = branch or line:match("^# branch%.head (.+)$")
	end
	if branch == "(detached)" then
		branch = "detached"
	end

	set(cwd, branch and (branch .. (dirty and " *" or "")) or "")
end

return M
