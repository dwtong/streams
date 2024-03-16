local Kria = {
  cv = {
    event_handlers = {},
    values = {},
  },
  mute = {
    event_handlers = {},
    values = {},
  },
}

local function crow_event_handler(event, value)
  if event.name == "cv" then
    channel = event.arg + 1
    Kria.cv.values[channel] = value
    if Kria.cv.event_handlers[channel] then
      Kria.cv.event_handlers[channel](value)
    end
  elseif event.name == "mute" then
    channel = event.arg
    Kria.mute.values[channel] = value
    if Kria.mute.event_handlers[channel] then
      Kria.mute.event_handlers[channel](value)
    end
  end
end

function Kria.init()
  print("init kria")
  crow.ii.kria.event = crow_event_handler
end

function Kria.cv.get(channel)
  crow.ii.kria.get("cv", channel - 1)
end

function Kria.mute.get(channel)
  crow.ii.kria.get("mute", channel)
end

return Kria
