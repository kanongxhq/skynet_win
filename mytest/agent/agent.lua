local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local cjson = require "cjson"
local proto = require "proto.proto"
local utils = require "utils.utils"

local CMD = {}
local REQUEST = {}
local client_fd

local function send_package(pack)
	local json = cjson.encode(pack)
	local package = string.pack(">s2", json)
	socket.write(client_fd, package)
end

function REQUEST:handshake()
	skynet.error("agent handshake")
	skynet.fork(function()
		while true do
			send_package({cmd = proto.s2c["handshake"]})
			skynet.sleep(500)
		end
	end)
	return {cmd = proto.s2c["chat"], msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.error("agent quit")
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

function REQUEST:login()
	skynet.error("agent login")
	return {cmd = proto.s2c["loginresp"], msg = "success" }
end

function REQUEST:logout()
	skynet.error("agent logout")
	return {cmd = proto.s2c["logoutresp"], msg = "success" }
end

function REQUEST:chat(data)
	skynet.error("agent chat",data)
	--skynet.call(WATCHDOG, "lua", "close", client_fd)
	return {cmd = proto.s2c["chat"], msg = data}
end



local function recv_data(tbData)
	if tbData and tbData.cmd then
			local cmdName = proto.c2s[tbData.cmd] 
			if cmdName then
				skynet.error("support client request",cmdName)
				local f = REQUEST[cmdName]
				if f then
					local response = f(tbData)
					if response then
						send_package(response)
					end
				else
					skynet.error("unsupport client request function")
				end
				
			else
				skynet.error("unsupport client request",tbData.cmd)
			end
	else
		skynet.error("client data error")
	end
end

-- 对已分包数据进行解包
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		-- 解包
		local json = skynet.tostring(msg,sz) 
		return cjson.decode(json)
	end,
	dispatch = function(_, _,tbData,...)
		--分发协议数据
		recv_data(tbData)
	end
}

function CMD.start(conf)
	skynet.error("agent start")
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	skynet.error("agent disconnect")
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
