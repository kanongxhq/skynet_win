local skynet       = require "skynet"
local socket       = require "socket"
local httpd        = require "http.httpd"
local sockethelper = require "http.sockethelper"
local cjson        = require "cjson"



local function response(id, code, msg, ...)
    local data = cjson.encode(msg)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), code, data, ...)
    if not ok then
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

-- 注册
local function register(id, msg)
    
    local ret = skynet.call("accountmgr", "lua", "register", msg)
    response(id, 200,ret)

end

-- 登录 --- 账号验证
local function login(id, msg)

    local ret = skynet.call("accountmgr", "lua", "vertify", msg)
    response(id, 200, ret)

end

local function handle(id)

    
    socket.start(id)
    local code, url, _, _, body = httpd.read_request(sockethelper.readfunc(id), 128)
    if not code or code ~= 200 then
        return
    end
    local msg = cjson.decode(body)
    if url == "/register" then
        register(id, msg)
    elseif url == "/login" then
        login(id, msg)
    end

end


skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
        handle(id)
        socket.close(id)
    end)
end)