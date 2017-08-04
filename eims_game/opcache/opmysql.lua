local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"

local CMD={}
local db 

local mysql_host        =  skynet.getenv "mysql_host" or "127.0.0.1" 
local mysql_port        =  tonumber(skynet.getenv "mysql_port" or 3306 )
local mysql_database    =  skynet.getenv "mysql_database" or "eimsgame" 
local mysql_user        =  skynet.getenv "mysql_user" or "root" 
local mysql_password    =  skynet.getenv "mysql_password" or "1" 

-------------------------------dump用作打印,数据库操作未防止代码注入

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

function CMD.insert(sql)

    local res = db:query(sql)     
    skynet.error("query result2=",dump(res))
    return res;
end

function CMD.delete(sql)



end

function CMD.query(sql)

    local res = db:query(sql) 
    --skynet.error("name:", res[1]["username"])
    --skynet.error("query result=",dump( res ) )
    return res

end

function CMD.update(sql)

end


skynet.start(function()

	db=mysql.connect{
		host=               mysql_host,
		port=               mysql_port,
		database=           mysql_database,
		user=               mysql_user,
		password=           mysql_password,
		max_packet_size =   1024 * 1024
	}
	if not db then
		skynet.error("failed to connect")
	end
    db:query("set names utf8")

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
    skynet.register(".opmysql")

	--db:disconnect()
	--skynet.exit()
end)

