-- streams

musicutil = require("musicutil")

local _crow = include("lib/crow")
local kria = include("lib/kria")

selected_note_index = 1
notes = { 2, 6, 9, 13 }

function init()
  _crow.init()
  kria.init()

  _crow.add_event_listener("input_trigger", 1, function()
    kria.get("cv", 1)
  end)

  _crow.add_event_listener("input_trigger", 2, function()
    kria.get("cv", 2)
  end)

  kria.add_event_listener("cv", 1, function(value)
    notes[1] = volts_to_note(value)
    print(string.format("kria event: channel: %s, value: %s", 1, value))
    redraw()
  end)

  kria.add_event_listener("cv", 2, function(value)
    notes[2] = volts_to_note(value)
    print(string.format("kria event: channel: %s, value: %s", 2, value))
    redraw()
  end)
end

function redraw()
  -- 128 x 64
  screen.clear()
  screen.level(2)
  screen.line_width(1)

  screen.move(0, 32)
  screen.line(127, 32)
  screen.close()

  screen.move(64, 0)
  screen.line(64, 63)
  screen.close()
  screen.stroke()

  screen.level(8)
  screen.font_face(8)
  screen.font_size(18)

  for i = 1, 4 do
    local x = (i == 1 or i == 3) and 20 or 84
    local y = (i == 1 or i == 2) and 20 or 52
    local note = notes[i]
    screen.move(x, y)
    screen.text(musicutil.note_num_to_name(note))
  end

  screen.update()
end

function key(n, z)
  if n == 3 and z == 1 then
    r()
  end
end

function r()
  norns.script.load("code/streams/streams.lua")
end

function volts_to_note(volts)
  return util.round(volts / (1 / 12))
end

function note_to_volts(note)
  return note * (1 / 12)
end
