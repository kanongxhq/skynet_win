local utils = require "utils"

local M = {}

-- 组包
function M.pack(id, msg)

    local length    =  #msg;
    local command   =  id;
    local version   =  1;
    local magicnum  =  24834    
    local timestamp =  os.time()
    local data = string.pack(">HHHHi8",length,command,version,magicnum,timestamp)..msg     
    return data

end


return M
