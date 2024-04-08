-- algae

musicutil = require("musicutil")

_crow = include("lib/crow")
kria = include("lib/kria")
scale = include("lib/scale")

selected_note_index = 1
notes = { 2, 6, 9, 13 }

function init()
  _crow.init()
  kria.init()

  init_params()
  crow.ii.jf.mode(1)

  _crow.add_event_listener("input_trigger", 1, function()
    kria.get("cv", 1)
  end)

  _crow.add_event_listener("input_trigger", 2, function()
    kria.get("cv", 2)
  end)

  kria.add_event_listener("cv", 1, function(value)
    print(string.format("kria event: channel: %s, value: %s", 1, value))
    local note, octave_offset = quantise_note_for_voice(value, 1)
    local volts = note_to_volts(note) + octave_offset
    notes[1] = note
    crow.ii.jf.play_note(volts, 1)
    redraw()
  end)

  kria.add_event_listener("cv", 2, function(value)
    notes[2] = volts_to_note(value)
    print(string.format("kria event: channel: %s, value: %s", 2, value))
    redraw()
  end)
end

function init_params()
  params:add_separator("global")
  params:add_option("global_scale_type", "scale", scale.scale_names(), 11)
  params:add_option("global_root", "root note", scale.circle_of_fifths_names(), 1)

  params:add_separator("voices")
  for i = 1, 4 do
    params:add_group("voice " .. i, 5)
    params:add_number("voice_root_offset_" .. i, "root offset", -11, 11, 0)
    params:add_number("voice_note_offset_" .. i, "note offset", 0, 11, 0)
    params:add_number("voice_octave_offset_" .. i, "octave offset", -3, 3, 0)
    params:add_number("voice_carve_" .. i, "carve", 0, 5, 0)
    params:add_number("voice_chance_" .. i, "chance", 0, 100, 100)
  end
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
  norns.script.load("code/algae/algae.lua")
end

function volts_to_note(volts)
  return util.round(volts / (1 / 12))
end

function note_to_volts(note)
  return note * (1 / 12)
end

function quantise_note_for_voice(cv_value, voice)
  local root_index = params:get("global_root")
  local scale_type = params:get("global_scale_type")
  local root_offset = params:get("voice_root_offset_" .. voice)
  local note_offset = params:get("voice_note_offset_" .. voice)
  local octave_offset = params:get("voice_octave_offset_" .. voice)
  local carve_amount = params:get("voice_carve_" .. voice)

  local root = scale.circle_of_fifths_at(root_index + root_offset)
  local carved_scale = scale.carved_scale(root, scale_type, carve_amount)
  local note = volts_to_note(cv_value)
  local clamped_note = note % 12
  local note_index = clamped_note + 1 + note_offset
  local quantised_note = scale.note_at_index(carved_scale, note_index)
  print(quantised_note)

  -- include octaves from provided cv value in octave offset
  octave_offset = math.floor(note / 12 + octave_offset) or 0

  return quantised_note, octave_offset
end
