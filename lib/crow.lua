local Crow = {}

local event_listeners = {
    input_trigger = {},
}

function Crow.init()
    --print("init crow")
    for i = 1, 2 do
        event_listeners.input_trigger[i] = {}

        crow.input[i].mode("change")
        crow.input[i].change = function(high)
            if high == true then
                local callbacks = event_listeners.input_trigger[i]
                for _, callback in ipairs(callbacks) do
                    if callback then
                        callback()
                    end
                end
            end
        end
    end
end

function Crow.add_event_listener(event, channel, callback)
    if event_listeners[event] == nil then
        --print("crow event '" .. event .. "' not supported.")
    end

    --print(string.format("added crow event handler. event: %s, channel: %d", event, channel))
    table.insert(event_listeners[event][channel], callback)
end

return Crow
