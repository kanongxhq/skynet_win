local skynet = require "skynet"
local socket = require "socket"
local cjson  = require "cjson"
local M = {}

function M:start(conf)

    self.gate = skynet.newservice("gate")
    skynet.call(self.gate, "lua", "open", conf)
    skynet.error("hall service listen on port "..conf.port)
    self:register_callback()

end

-------------------处理socket消息开始--------------------
function M:open(fd, addr)
    skynet.error("New client from : " .. addr)
    skynet.call(self.gate, "lua", "accept", fd)
end

function M:close(fd)
    skynet.error("socket close "..fd)
end

function M:error(fd, msg)
    skynet.error("socket error "..fd)
end

function M:warning(fd, size)
    skynet.error("socket warning "..fd)
end

-------------解析协议
function M:data(fd, msg)
    
    skynet.error(string.format("socket data fd = %d, len = %d ", fd, #msg))
    local command   = msg:byte(1)*256+ msg:byte(2)
    local version   = msg:byte(3)*256+ msg:byte(4)
    local magicnum  = msg:byte(5)*256+ msg:byte(6)
    local timestamp = string.unpack(">i8",string.sub(msg,7,14))    
    self:dispatch(fd, command,string.sub(msg,15))

end

--------------协议
---组包

local function pack(id,msg)

    local length    =  #msg;
    local command   =  id;
    local version   =  1;
    local magicnum  =  24834    
    local timestamp =  os.time()
    local data      = string.pack(">HHHHi8",length,command,version,magicnum,timestamp)..msg     
    return data

end


function M:register_callback()
    
    self.dispatch_tbl = 
    {
    
        [20001] = self.enter_hall,      ---进入主厅
        [20003] = self.auth_entication, ---实名认证
        [20005] = self.enter_small_hall,---进入具体游戏的大厅
        [20007] = self.create_room,     ---创建房间
        [20009] = self.join_room,       ---加入房间

    }
    self.proto_tb1=
    {
        ----对应协议返回
        [20001] = 20002,    --进入主厅
        [20003] = 20004,    --实名认证
        [20005] = 20006,    --进入具体游戏的大厅
        [20007] = 20008,    --创建房间
        [20009] = 20010,    --加入房间               
    
    }

end

function M:dispatch(fd, command, msgbody)
    local f = self.dispatch_tbl[command]
    if not f then
        skynet.error("can't find socket callback "..command)
        return
    end
    local ret_msg = f(self, fd, msgbody)
    if ret_msg then
        --pack(self.proto_tb1[command], ret_msg)
        socket.write(fd, pack(self.proto_tb1[command], ret_msg))
    end
end

function M:enter_hall(fd, msgbody)

    skynet.error("enter_hall ")
    ---test
    local isok = 1
    local data = string.pack(">B",isok) 
    local activities={
        10001,
        10002,
    }
    local jacs   = cjson.encode(activities)
    data = data..string.pack(">s2",jacs)   ----2代表两个字节字符串长度         
    local tasks = {
        10003,
        10004,
    }
    local jtks = cjson.encode(tasks)
    data = data..string.pack(">s2",jtks)      
    return data;

end

function M:auth_entication(fd, msgbody)
    skynet.error("auth_entication ")

end

function M:enter_small_hall(fd, msgbody)
    skynet.error("enter_small_hall ")

end

---均衡策略选择合适的服务器创建房间，客户端自动连接到房间服务器
function M:create_room(fd, msgbody)
    skynet.error("create_room ")
    local gametype  =  1;
    local roomid    =  2;
    local data  = string.pack(">BB",gametype,roomid) 
    local result = skynet.call("appmgrstar","lua","get_base_app_addr")
    return data..string.pack(">s2",cjson.encode(result)) 

end

---房间号获取服务器的ip,客户端自动连接到相应服务器
function M:join_room(fd, msgbody)
     skynet.error("join_room ")

end

-------------------网络消息回调函数结束------------------

return M