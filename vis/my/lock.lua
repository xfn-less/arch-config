-- 文件锁：提示其他 Vis 已打开同一文件，不强制禁止写入。
local vis = vis
local util = require("my.util")
local state_dir, shquote, os_ok = util.state_dir, util.shquote, util.os_ok
local mkdir_p, write_all = util.mkdir_p, util.write_all

local root = state_dir .. "/locks"
local held = {}
local pid

local function hash(path)
	local h = 5381
	for i = 1, #path do
		h = (h * 33 + path:byte(i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function current_pid()
	if pid then
		return pid
	end

	-- 直接读取 Vis 自身 PID，避免把临时 shell 当作文件持有者。
	local stat = assert(io.open("/proc/self/stat", "r"))
	pid = tostring(assert(stat:read("*n")))
	stat:close()
	return pid
end

local function alive(value)
	local n = tonumber(value)
	return n and os_ok("kill -0 " .. n .. " 2>/dev/null")
end

local function read_pid(dir)
	local file = io.open(dir .. "/pid", "r")
	if not file then
		return nil
	end

	local value = file:read("*l")
	file:close()
	return value
end

local function lock_dir(path)
	return root .. "/" .. hash(path) .. ".lock"
end

local function take(path)
	mkdir_p(root)

	local dir = lock_dir(path)
	if os_ok("mkdir " .. shquote(dir) .. " 2>/dev/null") then
		write_all(dir .. "/pid", current_pid() .. "\n")
		held[path] = dir
		return
	end

	local owner = read_pid(dir)
	if not alive(owner) then
		os.execute("rm -rf " .. shquote(dir))
		if os_ok("mkdir " .. shquote(dir) .. " 2>/dev/null") then
			write_all(dir .. "/pid", current_pid() .. "\n")
			held[path] = dir
		end
		return
	end

	if owner ~= current_pid() then
		vis:message("already open in another terminal\n\n" .. path .. "\npid: " .. tostring(owner))
	end
end

local function release(path)
	local dir = held[path]
	if not dir then
		return
	end

	os.execute("rm -rf " .. shquote(dir))
	held[path] = nil
end

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	local path = win and win.file and win.file.path
	if path and not held[path] then
		take(path)
	end
end)

vis.events.subscribe(vis.events.FILE_CLOSE, function(file)
	if file and file.path then
		release(file.path)
	end
end)

vis.events.subscribe(vis.events.QUIT, function()
	for path in pairs(held) do
		release(path)
	end
end)
