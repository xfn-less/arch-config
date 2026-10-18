-- 共用的路径和状态文件工具。
local home = os.getenv("HOME") or "."
local state_dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/vis"

local function shquote(value)
	return "'" .. tostring(value or ""):gsub("'", "'\\''") .. "'"
end

local function home_shorten(path)
	if path == home or path:sub(1, #home + 1) == home .. "/" then
		return "~" .. path:sub(#home + 1)
	end
	return path
end

local function os_ok(command)
	local ok, _, code = os.execute(command)
	return ok == true or ok == 0 or code == 0
end

local function mkdir_p(path)
	if not path or path == "" then
		return false
	end
	return os_ok("mkdir -p " .. shquote(path))
end

local function write_all(path, data)
	local file = io.open(path, "wb")
	if not file then
		return false
	end
	file:write(data or "")
	file:close()
	return true
end

return {
	state_dir = state_dir,
	shquote = shquote,
	home_shorten = home_shorten,
	os_ok = os_ok,
	mkdir_p = mkdir_p,
	write_all = write_all,
}
