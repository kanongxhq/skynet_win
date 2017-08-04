local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local db = {}

local command = {}

function command.GET(key)
	return db[key]
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		print("address: ",address,"cmd: ",cmd);
		local f = command[string.upper(cmd)]
		if f then
		-- 回应一个消息可以使用 skynet.ret(message, size) 。
		-- 它会将 message size 对应的消息附上当前消息的 session ，
		-- 以及 skynet.PTYPE_RESPONSE 这个类别，发送给当前消息的来源source 	 
			skynet.ret(skynet.pack(f(...))) -- 回应消息
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	----可以为自己注册一个别名。（别名必须在 32 个字符以内）
	skynet.register "SIMPLEDB"
end)
--skynet.pack(…) 返回一个 lightuserdata 和一个长度，符合 skynet.ret 的参数需求；
--与之对应的是 skynet.unpack(message, size) 
--它可以把一个 C 指针加长度的消息解码成一组 Lua 对象。