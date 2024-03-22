-- algae

musicutil = require("musicutil")
util = require("util")

jf = include("lib/jf")
kria = include("lib/kria")
scale = include("lib/scale")
-- txi = include("lib/txi")

function init_params()
  params:add_separator("global")
  params:add_option("global_scale_type", "scale", scale.scale_names(), 1)
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

  ----- CROW INIT -----

  crow.output[2].action = "pulse()"
  crow.output[4].action = "pulse()"

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

  ----- KRIA EVENT HOOKS -----

  kria.cv.event_handlers[1] = function(cv_value)
    local volts = quantise_note_for_voice(cv_value, 1)
    local chance = params:get("voice_chance_1")

    if kria.mute.values[1] == 0 and chance >= math.random(100) then
      jf.play_note(volts, 4)
    end
  end

  kria.cv.event_handlers[2] = function(cv_value)
    local chance = params:get("voice_chance_2")

    if kria.mute.values[2] == 0 and chance >= math.random(100) then
      local volts = quantise_note_for_voice(cv_value, 2)
      crow.output[1].volts = volts
      crow.output[2]()
    end

    chance = params:get("voice_chance_3")
    if kria.mute.values[3] == 0 and chance >= math.random(100) then
      local volts = quantise_note_for_voice(cv_value, 3)
      crow.output[3].volts = volts
      crow.output[4]()
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
    local cv_value = kria.cv.values[i]
    if cv_value then
      screen.text(cv_value)
    end
  end

  screen.update()
end

----- QUANT -----

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

  local octave_volts = math.floor(note / 12 + octave_offset) or 0

  return note_to_volts(quantised_note) + octave_volts
end
