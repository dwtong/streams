local Kria = {}

function Kria.enable(observer)
    crow.ii.kria.event = function(event, value)
        -- TODO: is this necessary?
        channel = event.name == "cv" and event.arg + 1 or event.arg
        local source = "kria_" .. channel
        observer:notify(source, event.name, value)
    end
end

function Kria.disable()
    crow.ii.kria.event = function() end
end

function Kria.get(event, channel)
    channel = event == "cv" and channel - 1 or channel
    crow.ii.kria.get(event, channel)
end

return Kria

-- local event_listeners = {
--     cv = {},
--     mute = {},
-- }

-- local function ii_event_listener(event, value)
--     local channel = event.name == "cv" and event.arg + 1 or event.arg
--     local callbacks = event_listeners[event.name][channel]

--     for _, callback in ipairs(callbacks) do
--         if callback then
--             callback.fn(value)
--         end
--     end
-- end

-- function Kria.init()
--     print("init kria")

--     for i = 1, 4 do
--         event_listeners.cv[i] = {}
--         event_listeners.mute[i] = {}
--     end

--     crow.ii.kria.event = ii_event_listener
-- end

-- function Kria.add_event_listener(kria_event, kria_channel, callback_id, callback_fn)
--     local callback = { id = callback_id, fn = callback_fn }

--     if event_listeners[kria_event] == nil then
--         print("kria event '" .. kria_event .. "' not supported.")
--         return
--     end

--     table.insert(event_listeners[kria_event][kria_channel], callback)
--     print(string.format("added kria event listener. event: %s, channel: %d", kria_event, kria_channel))
-- end

-- function Kria.remove_event_listener(kria_event, kria_channel, callback_id)
--     local callbacks = event_listeners[kria_event][kria_channel]
--     for index, callback in pairs(callbacks) do
--         if callback.id == callback_id then
--             table.remove(callbacks, index)
--             print(string.format("removed kria event listener. event: %s, channel: %d", kria_event, kria_channel))
--         end
--     end

--     tab.print(callbacks)
--     tab.print(event_listeners[kria_event][kria_channel])
-- end
