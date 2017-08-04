local skynet = require "skynet"
require "skynet.manager"

local player_mgr = require "player_mgr"

local M = {
    base_app_tbl = {}    
}
local CMD = {}

-- 创建   baseapp
local function create_base_apps()

    for i=1,2 do
        local addr = skynet.newservice("appdog", i)
        local info = 
        {
            addr = addr,
            port = 7000 + i
        }
        M.base_app_tbl[addr] = info
    end

end

local function start_base_apps()
    for _,v in pairs(M.base_app_tbl) do
        skynet.call(v.addr, "lua", "start", {
            port = v.port,
            maxclient = 20480,
            nodelay = true,
        })
    end
end

local function get_base_app_info(addr)

    return M.base_app_tbl[addr]

end



function CMD.start()

    -- 初始化base_app_mgr
    create_base_apps()
    start_base_apps()
    player_mgr:init()

end

-- 为玩家分配一个baseapp
function CMD.get_base_app_addr()

    return {ip = "192.168.4.30", port = "7001", token = "token"}

end


skynet.start(function()

    skynet.dispatch("lua", function(_, session, cmd, ...)
        local f = CMD[cmd]
        assert(f, "base_app_mgr can't dispatch cmd ".. (cmd or nil))
        if session > 0 then
            skynet.ret(skynet.pack(f(...)))
        else
            f(...)
        end    
    end)
    skynet.register("appmgrstar")   -- .appmgrstar注册本节点具名服务
    skynet.error("appmgrstar booted...")

end)
