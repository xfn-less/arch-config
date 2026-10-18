-- 手动格式化：普通模式按 =，需要对应 formatter 已安装。
local vis = vis
local shquote = require("my.util").shquote

local prettier_syntax = {}
for syntax in ("css html javascript json jsx markdown tsx typescript yaml"):gmatch("%S+") do
	prettier_syntax[syntax] = true
end

local function with_path(win, option)
	local path = win.file and win.file.path
	if not path or path == "" then
		return ""
	end
	return option .. shquote(path)
end

-- 按文件类型选择外部格式化程序。
local function default_command(win)
	local syntax = win.syntax or ""

	if prettier_syntax[syntax] then
		return "prettier" .. with_path(win, " --stdin-filepath ")
	end
	if syntax == "lua" then
		return "stylua -"
	end
	if syntax == "bash" or syntax == "sh" then
		return "shfmt" .. with_path(win, " --filename ") .. " -"
	end
	if syntax == "python" then
		return "ruff format" .. with_path(win, " --stdin-filename ") .. " -"
	end
	if syntax == "go" then
		return "gofmt"
	end

	return nil
end

-- 仅格式化当前文件，不自动保存；失败时保留原文。
local function format()
	local win = vis.win
	if not win or not win.file then
		return true
	end

	local command = default_command(win)
	if not command then
		vis:info("fmt: no formatter for syntax " .. tostring(win.syntax or "text"))
		return true
	end

	local file = win.file
	local before = file:content(0, file.size)
	local line = win.selection and win.selection.line or 1
	local col = win.selection and win.selection.col or 1
	local status, out, err = vis:pipe(file, { start = 0, finish = file.size }, command)

	if status ~= 0 then
		local msg = (err and err ~= "") and err or ("exit " .. tostring(status))
		vis:message("fmt failed:\n" .. msg:gsub("\n$", ""))
		return false
	end

	out = out or ""
	if out ~= before then
		file:delete(0, file.size)
		file:insert(0, out)
		win.selection:to(math.min(line, math.max(1, #file.lines)), math.max(1, col))
	end

	vis:info("fmt: " .. command)
	return true
end

vis.events.subscribe(vis.events.INIT, function()
	vis:map(vis.modes.NORMAL, "=", function()
		format()
		return true
	end, "format current file")
end)
