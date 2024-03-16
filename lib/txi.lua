local Txi = {
  param = {
    values = {},
  },
}

local function crow_event_handler(event, value)
  if event.name == "param" then
    Txi.param.values[event.arg] = value
  end
end

function Txi.init()
  print("init txi")
  crow.ii.txi.event = crow_event_handler
end

function Txi.param.get(channel)
  if channel == nil then
    for i = 1, 4 do
      crow.ii.txi.get("param", i)
    end
  else
    crow.ii.txi.get("param", channel)
  end
end

return Txi
