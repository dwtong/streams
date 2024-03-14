local Txi = {}

params = {}
Txi.params = params

function crow_event_handler(event, value)
  if event.name == "param" then
    params[event.arg] = value
  end
end

function Txi.init()
  print("init txi")
  for i = 1, 4 do
    params[i] = 0
  end

  crow.ii.txi.event = crow_event_handler
end

function Txi.get_params()
  for i = 1, 4 do
    crow.ii.txi.get("param", i)
  end
end

return Txi
