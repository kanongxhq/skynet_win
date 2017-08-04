local skynet = require "skynet"
require "skynet.manager"
local sock_cmd =  require "sockcmd"

-- 进入大厅的客户端维护心跳延后处理
-- create room order:the hall server select what server to client 
-- add room order:return the ip , port and playerinfo to client   

local CMD = {}
function CMD.start(conf)

    sock_cmd:start(conf)

end

skynet.start(function ()
     
     skynet.dispatch("lua", function(_, _, cmd,subcmd, ...)    
        if cmd == "socket" then
            local f = sock_cmd[subcmd]
            f(sock_cmd, ...)
        else
            local f = CMD[cmd]
            assert(f, cmd)
            if session == 0 then
                f(subcmd, ...)
            else
                skynet.ret(skynet.pack(f(subcmd, ...)))
            end
        end
     end)     
     skynet.register("hallstar")
end)
