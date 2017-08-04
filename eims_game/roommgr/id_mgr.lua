local game_list = require "game_list"

local M = {}

function M:init()
    math.randomseed(os.time())
    self.tbl =  {}
    for _,v in ipairs(game_list) do
        self.tbl[v.id] = {id = math.random(1,999999), ids = {}}
    end
end

function M:gen_id(game_id)
    local v = self.tbl[game_id]
    local ids = v.ids
    local id = nil
    while true do
        id = game_id * 1000000 + math.random(1,999999)
        if not ids[id] then
            ids[id] = os.time()
            break
        end
    end

    return id
end

return M
