-- 输入法：离开插入／替换模式时关闭中文输入。
local vis = vis

local last_mode = nil

local function input_mode(mode)
	return mode == vis.modes.INSERT or mode == vis.modes.REPLACE
end

local function observe_mode(win)
	if win ~= vis.win then
		return nil
	end

	local mode = vis.mode
	if input_mode(last_mode) and not input_mode(mode) then
		os.execute("fcitx5-remote -c >/dev/null 2>&1 &")
	end

	last_mode = mode
	return nil
end

vis.events.subscribe(vis.events.WIN_STATUS, observe_mode)
