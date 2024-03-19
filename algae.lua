-- algae

musicutil = require("musicutil")
util = require("util")

jf = include("lib/jf")
kria = include("lib/kria")
-- txi = include("lib/txi")

carve = {
  -- 5 note scales (pentatonic)
  [5] = { 1, 4, 2, 5, 3 },
  -- 7 note scales
  [7] = { 1, 5, 3, 7, 2, 6, 4 },
}

function init_params()
  params:add_separator("global")
  params:add_option("global_scale_type", "scale", generate_scale_names(), 1)
  params:add_option("global_root", "root note", generate_circle_of_fifths_names(), 1)

  params:add_separator("voices")
  for i = 1, 4 do
    params:add_group("voice " .. i, 4)
    params:add_number("voice_root_offset_" .. i, "root offset", -11, 11, 0)
    params:add_number("voice_note_offset_" .. i, "note offset", 0, 11, 0)
    params:add_number("voice_octave_offset_" .. i, "octave offset", -3, 3, 0)
    params:add_number("voice_carve_" .. i, "carve", 0, 4, 0)
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

  kria.cv.event_handlers[1] = function(cv_value)
    volts = quantise_note_for_voice(cv_value, 1)

    if kria.mute.values[1] == 0 then
      jf.play_note(volts, 4)
    end
  end

  kria.cv.event_handlers[2] = function(cv_value)
    if kria.mute.values[2] == 0 then
      volts = quantise_note_for_voice(cv_value, 2)
      crow.output[1].volts = volts
    end

    if kria.mute.values[3] == 0 then
      volts = quantise_note_for_voice(cv_value, voice)
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

function quantise_note_for_voice(cv_value, voice)
  root_index = params:get("global_root")
  scale_type = params:get("global_scale_type")
  root_offset = params:get("voice_root_offset_" .. voice)
  note_offset = params:get("voice_note_offset_" .. voice)
  octave_offset = params:get("voice_octave_offset_" .. voice)

  root = circle_of_fifths_at(root_index + root_offset)
  scale = musicutil.generate_scale(root, scale_type, 6)

  note = volts_to_note(cv_value)
  octave_volts = note / 12 + octave_offset
  clamped_note = note % 12
  note_index = clamped_note + 1 + note_offset
  quantised_note = scale[note_index]

  volts = note_to_volts(quantised_note) + octave_volts
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
