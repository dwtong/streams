-- algae

util = require("util")

jf = include("lib/jf")
kria = include("lib/kria")
txi = include("lib/txi")

-- major pentatonic
scale = { 0, 2, 4, 7, 9 }

function quantise(cv_value, note_offset)
  octave_volts = util.round(cv_value)
  note = volts_to_note(cv_value)
  note = note % 12 + note_offset
  quantised_note = scale[note % #scale + 1]
  volts = note_to_volts(quantised_note) + octave_volts + util.round(note / #scale)
  return volts
end

function init()
  print("init algae")
  jf.init()
  kria.init()
  txi.init()

  kria.cv_event_handlers[1] = function(value)
    offset = util.round(txi.get_param(1))
    volts = quantise(value, offset)
    jf.play_note(volts, 4)
  end

  kria.cv_event_handlers[2] = function(value)
    offset = util.round(txi.get_param(2))
    volts = quantise(value, offset)
    crow.output[1].volts = volts
    crow.output[2].volts = volts
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
      redraw()
      clock.sleep(1 / 30)
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

  local params = txi.get_params()
  for i = 1, #params do
    screen.move(55, 20 + i * 10)
    screen.text("txi param " .. i .. ": " .. util.round(params[i]))
  end

  screen.update()
end

function volts_to_note(volts)
  return util.round(volts / (1 / 12))
end

function note_to_volts(note)
  return note * (1 / 12)
end
