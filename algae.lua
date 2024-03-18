-- algae

musicutil = require("musicutil")
util = require("util")

jf = include("lib/jf")
kria = include("lib/kria")
-- txi = include("lib/txi")

scale = musicutil.generate_scale(0, "major pentatonic", 4)

function init_params()
  params:add_separator("global")
  params:add_number("global_scale", "scale", 1, 3, 1)
  params:add_option("global_root", "root note", generate_circle_of_fifths_names(), 1)

  params:add_separator("voices")
  for i = 1, 4 do
    params:add_group("voice " .. i, 4)
    params:add_number("voice_root_offset_" .. i, "root offset", -11, 11, 0)
    params:add_number("voice_carve_" .. i, "carve", 0, 4, 0)
    params:add_number("voice_note_offset_" .. i, "note offset", 0, 11, 0)
    params:add_number("voice_chance_" .. i, "chance", 0, 100, 100)
  end

  params:add_separator("just friends")

  params:add_separator("clouds")
  params:add_number("clouds_octave", "octave", 0, -5, 5)
  params:add_number("clouds_clock_division", "clock div", 1, 4, 1)
end

function init()
  print("init algae")
  jf.init()
  kria.init()

  init_params()

  kria.cv.event_handlers[1] = function(value)
    -- TODO: don't generate scale so frequently - params bang/action instead
    root_index = params:get("global_root")
    root_offset = params:get("voice_root_offset_1")
    root = circle_of_fifths_at(root_index + root_offset)
    scale = musicutil.generate_scale(root, "major pentatonic", 6)
    print("root note is " .. musicutil.note_num_to_name(root))

    note_offset = params:get("voice_note_offset_1")
    volts = quantise(value, note_offset, scale)

    if kria.mute.values[1] == 0 then
      jf.play_note(volts, 4)
    end
  end

  kria.cv.event_handlers[2] = function(value)
    if kria.mute.values[2] == 0 then
      -- voice 2
      offset = params:get("voice_note_offset_2")
      volts = quantise(value, offset)
      crow.output[1].volts = volts

      -- voice 3
      offset = params:get("voice_note_offset_3")
      volts = quantise(value, offset)
      crow.output[2].volts = volts
    end
  end

  for i = 1, 2 do
    crow.input[i].mode("change")
    crow.input[i].change = function(in_high)
      if in_high then
        kria.cv.get(i)
        kria.mute.get(i)
        redraw()
      end
    end
  end
end

function key(n, z)
  if n == 3 and z == 1 then
    r()
  end
end

function r()
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
    cv_value = kria.cv.values[i]
    if cv_value then
      screen.text(cv_value)
    end
  end

  screen.update()
end

function volts_to_note(volts)
  return util.round(volts / (1 / 12))
end

function note_to_volts(note)
  return note * (1 / 12)
end

function quantise(cv_value, note_offset, scale)
  if note_offset == nil then
    note_offset = 0
  end

  note = volts_to_note(cv_value)
  octave = note / 12
  clamped_note = note % 12
  note_index = clamped_note + 1 + note_offset
  quantised_note = scale[note_index]

  volts = note_to_volts(quantised_note + octave) -- + octave_volts + util.round(note / #scale)
  return volts
end

function circle_of_fifths_at(index)
  index = (index - 1) % 12
  if index % 2 == 0 then
    return index
  else
    return (index + 6) % 12
  end
end

function generate_circle_of_fifths_names()
  notes = {}
  for i = 1, 12 do
    note_num = circle_of_fifths_at(i)
    notes[i] = musicutil.note_num_to_name(note_num)
  end
  return notes
end
