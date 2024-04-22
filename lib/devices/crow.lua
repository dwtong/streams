local Crow = {}

function Crow.enable(observer)
    for input = 1, 2 do
        crow.input[input].mode("change")
        crow.input[input].change = function(is_high)
            local source = "crow_" .. input
            observer:notify(source, "trigger", is_high)
        end
    end
end

function Crow.disable()
    crow.input[channel].change = function() end
end

return Crow

-- local event_listeners = {
--     input_trigger = {},
-- }

-- function Crow.init()
--     --print("init crow")
--     for i = 1, 2 do
--         event_listeners.input_trigger[i] = {}

--         crow.input[i].mode("change")
--         crow.input[i].change = function(high)
--             if high == true then
--                 local callbacks = event_listeners.input_trigger[i]
--                 for _, callback in ipairs(callbacks) do
--                     if callback then
--                         callback()
--                     end
--                 end
--             end
--         end
--     end
-- end

-- function Crow.add_event_listener(event, channel, callback)
--     if event_listeners[event] == nil then
--         --print("crow event '" .. event .. "' not supported.")
--     end

--     --print(string.format("added crow event handler. event: %s, channel: %d", event, channel))
--     table.insert(event_listeners[event][channel], callback)
-- end
