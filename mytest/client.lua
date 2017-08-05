package.cpath = "luaclib/?.so"
package.path = "../mytest/?.lua"
package.path = package.path..";lualib/?.lua;examples/?.lua"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local proto = require "proto.proto"
local socket = require "clientsocket"
local cjson = require "cjson"

local fd = assert(socket.connect("127.0.0.1", 8888))

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	--print("package: ",package);
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(args)
	session = session + 1
	local str = cjson.encode(args)
	print("send_request ",str)
	send_package(fd, str)
	--print("Request:", session)
end

local last = ""

local function print_request(name, args)
	--print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end


local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
		print(v)
	end
end

send_request({cmd = proto.c2s["handshake"]})
send_request({cmd = proto.c2s["login"],name = "hello", pass = "eims" })
while true do
	dispatch_package()
	local msg = socket.readstdin()
	if msg then
		if msg == "quit" then
			send_request({cmd = proto.c2s["quit"]})
		else
			send_request({cmd = proto.c2s["chat"],data = msg})
		end
	else
		socket.usleep(1000)
	end
end
