-- 当前文件编辑；导航用原生 :e，工作目录用 :cd。
require("vis") -- 原生语法识别、单词和路径补全
local vis = vis

-- 基本设置与系统剪贴板。布尔值切换保持停用，旧实现见归档。
vis.events.subscribe(vis.events.INIT, function()
	vis:command("set theme mytheme-dark")
	for _, mode in ipairs({ vis.modes.NORMAL, vis.modes.VISUAL }) do
		vis:map(mode, " y", "<vis-register>+<vis-operator-yank>", "yank to system clipboard")
		vis:map(mode, " p", "<vis-register>+<vis-put-after>", "paste from system clipboard")
	end
end)
vis.events.subscribe(vis.events.WIN_OPEN, function()
	vis:command("set autoindent on")
	vis:command("set tabwidth 2")
end)

-- 按功能加载；不用某项时注释对应一行。
require("my.formatter") -- 手动格式化
require("my.fcitx") -- 退出插入时关闭中文输入
require("my.cursor") -- 记住光标位置
require("my.lock") -- 重复打开文件提醒
require("my.status") -- 自定义状态栏
