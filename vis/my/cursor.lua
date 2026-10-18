-- 光标位置：保存在 ~/.local/state/vis/cursors.tsv，重新打开时恢复。
local vis = vis
local util = require("my.util")
local state_dir, mkdir_p = util.state_dir, util.mkdir_p

local cursor_path = state_dir .. "/cursors.tsv"
local cursor_max = 1000

local cursors = {}
local order = {}

local function ignored(path)
	return not path or path:match("COMMIT_EDITMSG$") or path:match("git%-rebase%-todo$")
end

local function move_front(list, path)
	if not path or path == "" then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == path then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, path)
end

local function read()
	cursors = {}
	order = {}

	local file = io.open(cursor_path, "r")
	if not file then
		return
	end
	for line in file:lines() do
		local path, pos = line:match("^([^\t]+)\t(%d+)$")
		if path and pos then
			cursors[path] = tonumber(pos)
			table.insert(order, path)
		end
	end
	file:close()
end

local function write()
	mkdir_p(state_dir)

	local file = io.open(cursor_path, "w")
	if not file then
		return
	end

	local seen = {}
	local written = 0
	for _, path in ipairs(order) do
		local pos = cursors[path]
		if pos and not seen[path] then
			file:write(path, "\t", tostring(pos), "\n")
			seen[path] = true
			written = written + 1
			if written >= cursor_max then
				break
			end
		end
	end
	file:close()
end

local function remember(win)
	if not win or not win.file or not win.file.path or not win.selection then
		return
	end

	local path = win.file.path
	if ignored(path) then
		return
	end

	move_front(order, path)
	cursors[path] = win.selection.pos or 0
end

local function restore(win)
	if not win or not win.file or not win.file.path or not win.selection then
		return
	end

	local path = win.file.path
	if ignored(path) then
		return
	end

	local pos = cursors[path]
	if pos and pos > 0 and pos <= win.file.size then
		win.selection.pos = pos
		vis:feedkeys("zz")
	end
end

vis.events.subscribe(vis.events.INIT, read)
vis.events.subscribe(vis.events.WIN_OPEN, restore)
vis.events.subscribe(vis.events.WIN_CLOSE, remember)
vis.events.subscribe(vis.events.QUIT, function()
	for win in vis:windows() do
		remember(win)
	end
	write()
end)
