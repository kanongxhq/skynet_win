local skynet = require "skynet"
local c = require "skynet.core"
--����һ�� C ����
function skynet.launch(...)
	local addr = c.command("LAUNCH", table.concat({...}," "))
	if addr then
		return tonumber("0x" .. string.sub(addr , 2))
	end
end
--ǿ��ɱ��һ������
function skynet.kill(name)
	if type(name) == "number" then
		skynet.send(".launcher","lua","REMOVE",name, true)
		name = skynet.address(name)
	end
	c.command("KILL",name)
end
--�˳� skynet ���̡�
function skynet.abort()
	c.command("ABORT")
end

local function globalname(name, handle)
	local c = string.sub(name,1,1)
	assert(c ~= ':')
	if c == '.' then
		return false
	end

	assert(#name <= 16)	-- GLOBALNAME_LENGTH is 16, defined in skynet_harbor.h
	assert(tonumber(name) == nil)	-- global name can't be number

	local harbor = require "skynet.harbor"

	harbor.globalname(name, handle)

	return true
end
--- ������ע��һ�����֡�
function skynet.register(name)
	if not globalname(name) then
		c.command("REG", name)
	end
end
-- Ϊһ����������
function skynet.name(name, handle)
	if not globalname(name, handle) then
		c.command("NAME", name .. " " .. skynet.address(handle))
	end
end

local dispatch_message = skynet.dispatch_message
--��������ʵ��Ϊ��Ϣת��������һ����Ϣ����ת����
function skynet.forward_type(map, start_func)
	c.callback(function(ptype, msg, sz, ...)
		local prototype = map[ptype]
		if prototype then
			dispatch_message(prototype, msg, sz, ...)
		else
			dispatch_message(ptype, msg, sz, ...)
			c.trash(msg, sz)
		end
	end, true)
	skynet.timeout(0, function()
		skynet.init_service(start_func)
	end)
end
-- ������Ϣ�ٴ���
function skynet.filter(f ,start_func)
	c.callback(function(...)
		dispatch_message(f(...))
	end)
	skynet.timeout(0, function()
		skynet.init_service(start_func)
	end)
end
--��ǰ skynet ��������һ��ȫ�ֵķ����ء�
function skynet.monitor(service, query)
	local monitor
	if query then
		monitor = skynet.queryservice(true, service)
	else
		monitor = skynet.uniqueservice(true, service)
	end
	assert(monitor, "Monitor launch failed")
	c.command("MONITOR", string.format(":%08x", monitor))
	return monitor
end

return skynet
--[[

��.��ͷ����������ͬһ skynet �ڵ�����Ч�ģ���ڵ�� skynet ����Ա�Ľڵ��µ� .
��ͷ�����ֲ��ɼ�����ͬ�� skynet �ڵ���Զ�����ͬ�� . ��ͷ�����֡�

]]--