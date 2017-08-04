--为了方便做负载均衡，所以每个app都提供好几个游戏玩法，
--将来可以将他们分布在不同的物理机上面,物理机之间使用 sproto协议实现rpc

local skynet = require "skynet"
local player_mgr  = require "player_mgr"
local msg_handler = require "msg_handler.init"
local sock_mgr = require "sock_mgr"

local CMD = {}
function CMD.start(conf)

    sock_mgr:start(conf)  -- listen
    player_mgr:init()     -- empty
    msg_handler.init()    -- 注册几个函数
    
end

function CMD.room_begin(msg)

    local obj = player_mgr:get_by_account(msg.account)
    if not obj then
        return
    end
    obj:room_begin(msg)

end

function CMD.sendto_client(account, proto_name, msg)
    local obj = player_mgr:get_by_account(account)
    if not obj then
        return
    end
    obj:sendto_client(proto_name, msg)
end


skynet.start(function()
    skynet.dispatch("lua", function(_, session, cmd, subcmd, ...)
        if cmd == "socket" then
            sock_mgr[subcmd](sock_mgr, ...)
            return
        end
        local f = CMD[cmd]
        assert(f, "can't find dispatch handler cmd = "..cmd)
        if session > 0 then
            skynet.error("  ok ")
            return skynet.ret(skynet.pack(f(subcmd, ...)))
        else
            f(subcmd, ...)
        end
    end)
end)