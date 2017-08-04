local skynet = require "skynet"
require "skynet.manager"
local init   = require "init"

---以下服务都未考虑玩家断线的可能，各个服务相互独立
local debug_console_port        = tonumber( skynet.getenv "debug_console_port" or 6001 )
local httplisten_port           = tonumber( skynet.getenv "httplisten_port" or 6002 )
local hallstar_port           = tonumber( skynet.getenv "hallstar_port" or 6003 )


skynet.start(function ()
    
    skynet.error("main", "server starting") 
    ------调试 
	skynet.newservice("debug_console",debug_console_port)   

    -----启动数据库,后面要做成连接池,具名服务
    local opmysql= skynet.uniqueservice("opmysql")

    
    ----启动玩家管理器
    skynet.uniqueservice("playermgr")

    ----启动登录/注册服务器http,可扩展做负载均衡(大厅)     
    skynet.newservice("httplisten",httplisten_port)   
    skynet.newservice("accountmgr")
    skynet.call("accountmgr", "lua", "start")    

    --启动app管理器,初步设计用来主节点的负载均衡
    skynet.uniqueservice("appmgrstar")
    skynet.call("appmgrstar", "lua", "start")    

    -- 各种不同的麻将类型管理器，它为app_mgr提供服务
    skynet.uniqueservice("areastar")
    skynet.call("areastar", "lua", "start")

    --每创建一个房间，不区分具体房间类型，管理各类房间，设计的有点绕。
    skynet.uniqueservice("roomstar")

    --启动大厅服务器 
    skynet.uniqueservice("hallstar")
    skynet.call("hallstar", "lua", "start", {
        port = hallstar_port,
        maxclient = 20480,
        nodelay = true,
    })

    skynet.exit();
end)


