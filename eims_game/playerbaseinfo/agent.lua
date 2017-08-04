local skynet = require "skynet"

local CMD = {}

local playermgr = ...

function CMD.persistent()


end

function CMD.check_idle()

	-- local now = skynet.time()
	-- local last_active = agentstate.last_active
	-- local timepassed = now - last_active
	-- if timepassed >= agent_session_expire then
	-- logger.debug("agent", "user uid", agentstate.userdata.uid, "recycleable detected")
	-- skynet.call(watchdog, "lua", "recycle_agent", agentstate.userdata.uid, skynet.self())
	-- end

end

function CMD.logout()

	-- agentstate.fd = nil
	-- agentstate.ip = nil
	-- agentstate.afk = true
	-- libroom.leave_room(agentstate.userdata.uid)
	-- return true

end

function CMD.recycle()

	-- local uid = agentstate.userdata.uid
	-- agentstate.fd = nil
	-- agentstate.ip = nil
	-- agentstate.afk = true
	-- agentstate.last_active = 0
	-- agentstate.userdata = {}

end

function CMD.load_user_data(uid)
	-- uid = tonumber(uid)
	-- local init_status = false
	-- local userdata = libpersistent.load_user_data(uid)
	-- if not userdata then
	-- 	init_status = false
	-- else
	-- 	agentstate.userdata = userdata

	-- 	init_status = true
	-- end
	-- return init_status
end



skynet.start(function()

	skynet.dispatch("lua", function(_, _, command, ...) 
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)

end)