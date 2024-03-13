-- algae

musicutil = require("musicutil")
util = require("util")

function init()
  crow.ii.jf.mode(1)
  for i = 1, 4 do
    crow.output[i].volts = 0
  end

  for i = 1, 2 do
    crow.input[i].mode("change")
    crow.input[i].change = function(state)
      if state then
        crow.ii.kria.get("cv", i - 1)
      end
    end
  end

  clock.run(function()
    while true do
      get_txi_params()
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

  for i = 1, 4 do
    screen.move(55, 20 + i * 10)
    screen.text("txi param " .. i .. ": " .. util.round(txi.params[i]))
  end

  screen.update()
end

----- TXI -----

txi = {
  params = {},
}

crow.ii.txi.event = function(event, value)
  if event.name == "param" then
    txi.params[event.arg] = value
  end
end

for i = 1, 4 do
  txi.params[i] = 0
end

function get_txi_params()
  for i = 1, 4 do
    crow.ii.txi.get("param", i)
  end
end

----- KRIA -----

-- major pentatonic
scale = { 0, 2, 4, 7, 9 }

crow.ii.kria.event = function(event, value)
  if event.name == "cv" then
    kria_channel = event.arg + 1
    kria_note = util.round(value / (1 / 12))
    note = scale[kria_note % #scale + 1]

    if kria_channel == 1 then
      play_note(note / 12, 1)
    end
  end
end

----- JF -----

function play_note(pitch, level)
  crow.ii.jf.play_note(pitch, level)
end
