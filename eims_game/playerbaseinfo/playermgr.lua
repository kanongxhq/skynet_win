local skynet = require "skynet"
require "skynet.manager"
local data  = require "agent"

local CMD ={}
local SOCKET={}
local agentpool = {}
local user_agent = {}

local recycle_queue = {}

local agentpool_min_size        = tonumber( skynet.getenv "agentpool_min_size" or 10 )
local precreate_check_interval  = tonumber( skynet.getenv "precreate_check_interval" or 10 )
local check_idle_accumulated    = tonumber( skynet.getenv "check_idle_accumulated" or 0 )
local agent_checkidle_interval  = tonumber( skynet.getenv "agent_checkidle_interval" or 60 )
local persistent_accumulated    = tonumber( skynet.getenv "persistent_accumulated" or 0 )
local recycle_accumulated       = tonumber( skynet.getenv "recycle_accumulated" or 0 )
local agent_bgsave_interval     = tonumber( skynet.getenv "agent_bgsave_interval" or 600 )


local function precreate_agents_to_freepool()
	if #agentpool < agentpool_min_size then
		local need_create = agentpool_min_size - #agentpool
		skynet.error("watchdog", "precreate", need_create, "agents in freepool")
		for i = 1, need_create do
			 local agent = skynet.newservice("agent", skynet.self())
			 agentpool[#agentpool + 1] = agent
		end
	end
end


local function check_idle_agents()
	--let agent get chance to report recycleable

	for _, agent in pairs(user_agent) do
		skynet.call(agent, "lua", "check_idle")
	end

end

local function bgsave_agent_state()

	--agent do state persistent when necessary
	for _, agent in pairs(user_agent) do
		skynet.call(agent, "lua", "persistent")
	end

end


function logout_user(uid)
	local agent = user_agent[uid]
	if agent then
		--logout from gateserver, gateserver then informs loginserver to logout
		--skynet.call(gateservice, "lua", "logout", uid)

		local can_recycle = skynet.call(agent, "lua", "logout")
		if can_recycle then
			skynet.call(agent, "lua", "persistent")
			skynet.call(agent, "lua", "recycle")

			user_agent[uid] = nil
			agentpool[#agentpool + 1] = agent

		end
	end
end


local function watchdog_timer()
	precreate_agents_to_freepool()

	check_idle_accumulated = check_idle_accumulated + 1
	persistent_accumulated = persistent_accumulated + 1
	recycle_accumulated = recycle_accumulated + 1

	if check_idle_accumulated >= agent_checkidle_interval then
		
		check_idle_accumulated = 0		
		check_idle_agents()
	
	end

	if persistent_accumulated >= agent_bgsave_interval then
		
		persistent_accumulated = 0
		bgsave_agent_state()
	
	end

	if recycle_accumulated >= 60 then
		recycle_accumulated = 0

		if #recycle_queue > 0 then
			for _, item in pairs(recycle_queue) do
				local uid = item.uid
				logout_user(uid)
			end

			recycle_queue = {}
		end
	end

	skynet.timeout(precreate_check_interval * 100, watchdog_timer)
end

----------------------------------------------------------------------------------

function CMD.alloc_agent(uid)
	local agent 
	if user_agent[uid] then
		agent = user_agent[uid]
	else
		if #agentpool > 0 then
			agent = table.remove(agentpool)    ----take a agent from agentpool
		else
			agent = skynet.newservice("agent", skynet.self())
		end

		user_agent[uid] = agent	               --- save the online uid		
		local init = skynet.call(agent, "lua", "load_user_data", uid)
		if not init then
			agentpool[#agentpool + 1] = agent
			agent = nil
			user_agent[uid] = nil
		end
	end
	return agent
end

function CMD.recycle_agent(uid, agent)

	recycle_queue[#recycle_queue + 1] = {
		uid = uid,
		agent = agent,
	}

end

function CMD.logout(uid)

	logout_user(uid)
	return true

end


function CMD.start(conf)


end


skynet.start(function ()
    
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

    skynet.register("playermgr")              						-- 注册具名服务
 	precreate_agents_to_freepool()         	 						-- 预创建agents池
	skynet.timeout(precreate_check_interval * 100, watchdog_timer)  --10秒检查,skynet的时间精度为 1/100秒

end)




