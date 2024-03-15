-- algae

util = require("util")

jf = include("lib/jf")
kria = include("lib/kria")
txi = include("lib/txi")

-- major pentatonic
scale = { 0, 2, 4, 7, 9 }

function init()
  print("init algae")
  jf.init()
  kria.init()
  txi.init()

  for i = 1, 4 do
    kria.cv_event_handlers[i] = function(note)
      print(string.format("kria cv event. channel: %i, note: %i", i, note))
      quantised_note = scale[note % #scale + 1]
      jf.play_note(quantised_note / 12, 1, i)
    end
  end

  for i = 1, 2 do
    crow.input[i].mode("change")
    crow.input[i].change = function(in_high)
      if in_high then
        kria.get_cv(i)
        redraw()
      end
    end
  end

  clock.run(function()
    while true do
      txi.get_params()
      redraw()
      clock.sleep(0.1)
    end
  end)
end

function key(n, z)
  if n == 3 and z == 1 then
    reload()
  end
end

function reload()
  norns.script.load("code/algae/algae.lua")
end

function redraw()
  screen.clear()
  screen.level(5)

  screen.move(5, 20)
  screen.font_size(15)
  screen.text("algae")

  screen.font_size(8)

  if norns.crow.connected() then
    screen.move(5, 40)
    screen.text("crowing!")
  end

  screen.move(5, 50)
  screen.text("k3: reload")

  screen.move(55, 10)
  screen.text("kria: ")
  for i = 1, 4 do
    screen.move(69 + i * 10, 10)
    cv_value = kria.cv_values[i]
    if cv_value then
      screen.text(cv_value)
    end
  end

  for i = 1, 4 do
    screen.move(55, 20 + i * 10)
    screen.text("txi param " .. i .. ": " .. util.round(txi.params[i]))
  end

  screen.update()
end
