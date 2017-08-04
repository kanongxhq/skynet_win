local skynet = require "skynet"
require "skynet.manager"
local cjson        = require "cjson"
local CMD = {}
local opmysql


----该账号是否已经登录,等等.... 

---验证账号
function CMD.vertify(msg)

    local str = string.format("select * from users where username ='%s'",msg.name)
    local result = skynet.call(opmysql,"lua","query",str)
    if(msg.name == result[1]["username"]) then
        return 1
    else
        return -1;
    end
    return -1
end

----注册账号
function CMD.register(msg)

    local str = string.format("select * from users where username = '%s'",msg.name)
    local result = skynet.call(opmysql,"lua","query",str)
    if #result == 0 then 
        skynet.error("str is not exsit")  
        -- 可以插入数据
        local str1 = string.format("insert into users values('%s','%s',0)",msg.name,msg.password);
        local result2 = skynet.call(opmysql,"lua","insert",str1)
        return {1,"ok"}
    else
        return {-1 , "exist acccount"}
    end
    return  {-1,"exist acccount"}

end

function CMD.start(msg)

end


skynet.start(function()
    opmysql = skynet.localname(".opmysql")
    skynet.dispatch("lua", function(_, session, cmd, ...)
        local f = CMD[cmd]
        if not f then
            return
        end     
        if session > 0 then
            skynet.ret(skynet.pack(f(...)))
        else
            f(...)
        end
    end)
    skynet.register("accountmgr")
end)
