-- 手动格式化：普通模式按 =。
-- 泛前端（JS/TS/React + JSON/CSS/HTML/MD/YAML 等）用 biome；不含 Vue/Svelte/Astro。
-- Go 用 gofmt。
local vis = vis
local shquote = require("my.util").shquote

local syntax_ext = {
	javascript = ".js",
	typescript = ".ts",
	json = ".json",
	css = ".css",
	sass = ".scss",
	html = ".html",
	markdown = ".md",
	yaml = ".yaml",
}

local frontend_ext = {
	[".js"] = true,
	[".mjs"] = true,
	[".cjs"] = true,
	[".jsx"] = true,
	[".ts"] = true,
	[".mts"] = true,
	[".cts"] = true,
	[".tsx"] = true,
	[".json"] = true,
	[".jsonc"] = true,
	[".css"] = true,
	[".scss"] = true,
	[".html"] = true,
	[".htm"] = true,
	[".md"] = true,
	[".mdx"] = true,
	[".yaml"] = true,
	[".yml"] = true,
	[".graphql"] = true,
	[".gql"] = true,
}

local function path_ext(path)
	return path:match("%.[^./]+$") or ""
end

local function biome_path(win)
	local path = win.file and win.file.path
	if path and path ~= "" then
		local ext = path_ext(path):lower()
		if frontend_ext[ext] then
			return path
		end
	end

	local ext = syntax_ext[win.syntax or ""]
	if not ext then
		return nil
	end
	return (path and path ~= "") and path or ("untitled" .. ext)
end

local function default_command(win)
	if (win.syntax or "") == "go" then
		return "gofmt"
	end

	local path = biome_path(win)
	if not path then
		return nil
	end
	-- HTML 默认关闭，需显式打开（不含 Vue/Svelte/Astro 扩展名则不会误伤）
	return "biome format --html-formatter-enabled=true --stdin-file-path " .. shquote(path)
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
