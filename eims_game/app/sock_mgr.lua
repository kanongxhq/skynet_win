local skynet = require "skynet"
local socket = require "socket"

local M = {
    dispatch_tbl2 = {} ,   
    dispatch_tbl = {},
    authed_fd = {}
}

function M:start(conf)
    self.gate = skynet.newservice("gate")
    skynet.call(self.gate, "lua", "open", conf)
    skynet.error("login service listen on port "..conf.port)
    self:register_callback_online()
end

-------------------处理socket消息开始--------------------
function M:open(fd, addr)
    skynet.error("App New client from : " .. addr)
    skynet.call(self.gate, "lua", "accept", fd)
end

function M:close(fd)
    self:close_conn(fd)
    skynet.error("socket close "..fd)
end

function M:error(fd, msg)
    self:close_conn(fd)
    skynet.error("socket error "..fd.." msg "..msg)
end

function M:warning(fd, size)
    self:close_conn(fd)
    skynet.error(string.format("%dK bytes havn't send out in fd=%d", size, fd))
end

function M:data(fd, msg)
    skynet.error(string.format("recv socket data fd = %d, len = %d ", fd, #msg))
    local command   = msg:byte(1)*256+ msg:byte(2)
    local version   = msg:byte(3)*256+ msg:byte(4)
    local magicnum  = msg:byte(5)*256+ msg:byte(6)
    local timestamp = string.unpack(">i8",string.sub(msg,7,14))    
    self:dispatch(fd, command,string.sub(msg,15))
end

function M:close_conn(fd)
    self.authed_fd[fd] = nil
end

-------------------处理socket消息结束--------------------

-------------------网络消息回调函数开始------------------

local function pack(id,msg)

    local length    =  #msg;
    local command   =  id;
    local version   =  1;
    local magicnum  =  24834    
    local timestamp =  os.time()
    local data      = string.pack(">HHHHi8",length,command,version,magicnum,timestamp)..msg     
    return data

end

------由其他服务注册协议

function M:register_callback(name, func, obj)

    self.dispatch_tbl[name] = {func = func, obj = obj}

end

------预定制协议
function M:register_callback_online()

    self.dispatch_tbl2 = 
    {    
        [10024] = self.leave_room,      ---离开房间
    }
    self.proto_tb1=
    {
        ----对应协议返回
        [10024] = 10025,                --离开房间返回                 
    }

end

function M:dispatch(fd, command, msgbody)
    local f = self.dispatch_tbl2[command]
    if not f then
        skynet.error("can't find socket callback "..command)
        return
    end
    local ret_msg = f(self, fd, msgbody)
    if ret_msg then
        socket.write(fd, pack(self.proto_tb1[command], ret_msg))
    end
end


function M:leave_room(fd, msgbody)

    skynet.error("leave_room ")
    ---test
    local isok = 1
    local data = string.pack(">B",isok)     
    return data;

end
-------------------网络消息回调函数结束------------------

return M
