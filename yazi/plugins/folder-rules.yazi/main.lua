-- https://yazi-rs.github.io/docs/tips#folder-rules
local function under_downloads(cwd)
	local s = tostring(cwd)
	return s:find("/Downloads/") or s:find("/Downloads$")
end

local function setup()
	ps.sub("ind-sort", function(opt)
		local cwd = cx.active.current.cwd
		if under_downloads(cwd) then
			opt.by, opt.reverse, opt.dir_first = "mtime", true, false
		else
			opt.by, opt.reverse, opt.dir_first = "natural", false, true
		end
		return opt
	end)
end

return { setup = setup }
