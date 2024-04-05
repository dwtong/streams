local Kria = {}

--   local values = {
--     cv = {},
--     mute = {},
--   },
-- }

local event_listeners = {
  cv = {},
  mute = {},
}

local function ii_event_listener(event, value)
  local channel = event.name == "cv" and event.arg + 1 or event.arg
  local callbacks = event_listeners[event.name][channel]

  for _, callback in ipairs(callbacks) do
    if callback then
      callback(value)
    end
  end
end

function Kria.init()
  print("init kria")

  for i = 1, 4 do
    event_listeners.cv[i] = {}
    event_listeners.mute[i] = {}
  end

  crow.ii.kria.event = ii_event_listener
end

function Kria.get(event, channel)
  channel = event == "cv" and channel - 1 or channel
  crow.ii.kria.get(event, channel)
end

function Kria.add_event_listener(event, channel, callback)
  if event_listeners[event] == nil then
    print("kria event '" .. event .. "' not supported.")
  end

  print(string.format("added kria event handler. event: %s, channel: %d", event, channel))
  table.insert(event_listeners[event][channel], callback)
end

return Kria
