-- algae

local musicutil = require("musicutil")

local _crow = include("lib/crow")
local kria = include("lib/kria")
local nb = include("lib/nb/lib/nb")
local scale = include("lib/scale")

local cv_source_options = { "crow 1", "crow 2", "crow(ii) 1", "crow(ii) 2", "kria 1", "kria 2", "kria 3", "kria 4" }
local trigger_source_options = { "crow 1", "crow 2" }
local trigger_sources = {}
local cv_sources = {}

-- TESTING: remove me
selected_note_index = 1
notes = { 2, 6, 9, 13 }

function init()
    _crow.init()
    kria.init()
    nb:init()

    init_params()

    crow.ii.jf.mode(1)

    -- trigger listener
    _crow.add_event_listener("input_trigger", 1, function()
        kria.get("cv", 1)
    end)

    -- cv listener, triggered by trigger
end

function set_trigger_source(channel, source_index)
    local source = trigger_source_options[source_index]
    print(string.format("set trigger source %s for channel %i", source, channel))
    -- remove old event listener
    -- add new event listener
end

function source_name_and_channel(source_index)
    local source = cv_source_options[source_index]
    local source_name, source_channel

    for name, chan in string.gmatch(source, "(%g+)%s(%d)") do
        source_name = name
        source_channel = tonumber(chan)
    end

    return source_name, source_channel
end

function set_cv_source(channel, source_index)
    local existing_source_index = cv_sources[channel]
    if existing_source_index then
        remove_cv_source(channel, existing_source_index)
    end
    add_cv_source(channel, source_index)
end

function remove_cv_source(channel, source_index)
    local source_name, source_channel = source_name_and_channel(source_index)
    print(string.format("remove cv source. name: %s, channel: %i for channel %i", source_name, source_channel, channel))
    if source_name == "kria" then
        kria.remove_event_listener("cv", source_channel, channel)
    end
end

function add_cv_source(channel, source_index)
    local source_name, source_channel = source_name_and_channel(source_index)
    cv_sources[channel] = source_index
    local callback_fn = function(note)
        print(string.format("kria event: channel: %s, value: %s", 1, note))
        local quantised_note = quantise_note_for_channel(note, 1)
        notes[1] = quantised_note
        local player = params:lookup_param("output_channel_1"):get_player()
        player:play_note(quantised_note, 0.5, 0.2)
        redraw()
    end
    print(string.format("add cv source. name: %s, channel: %i for channel %i", source_name, source_channel, channel))
    if source_name == "kria" then
        -- TODO: also need to add kria.get somehow
        kria.add_event_listener("cv", source_channel, channel, callback_fn)
    end
end

function init_params()
    params:add_separator("global")
    params:add_option("global_scale_type", "scale", scale.scale_names(), 11)
    params:add_option("global_root", "root note", scale.circle_of_fifths_names(), 1)

    params:add_separator("input trigger sources")
    for i = 1, 4 do
        params:add_option("input_trigger_source_" .. i, "channel " .. i, trigger_source_options, 1)
        params:set_action("input_trigger_source_" .. i, function(source)
            set_trigger_source(i, source)
        end)
    end

    params:add_separator("input cv (note) sources")
    for i = 1, 4 do
        params:add_option("input_cv_source_" .. i, "channel " .. i, cv_source_options, 1)
        params:set_action("input_cv_source_" .. i, function(source)
            set_cv_source(i, source)
        end)
    end

    params:add_separator("transformations")
    for i = 1, 4 do
        params:add_group("channel " .. i, 5)
        params:add_number("channel_root_offset_" .. i, "root offset", -11, 11, 0)
        params:add_number("channel_note_offset_" .. i, "note offset", 0, 11, 0)
        params:add_number("channel_octave_offset_" .. i, "octave offset", -3, 3, 0)
        params:add_number("channel_carve_" .. i, "carve", 0, 5, 0)
        params:add_number("channel_chance_" .. i, "chance", 0, 100, 100)
    end

    params:add_separator("output destinations")
    for i = 1, 4 do
        nb:add_param("output_channel_" .. i, "channel " .. i)
    end
    params:add_separator("output params")
    nb:add_player_params()
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

function quantise_note_for_channel(cv_value, channel)
    local root_index = params:get("global_root")
    local scale_type = params:get("global_scale_type")
    local root_offset = params:get("channel_root_offset_" .. channel)
    local note_offset = params:get("channel_note_offset_" .. channel)
    local octave_offset = params:get("channel_octave_offset_" .. channel)
    local carve_amount = params:get("channel_carve_" .. channel)

    local root = scale.circle_of_fifths_at(root_index + root_offset)
    local carved_scale = scale.carved_scale(root, scale_type, carve_amount)
    local note = volts_to_note(cv_value)
    local clamped_note = note % 12
    local note_index = clamped_note + 1 + note_offset
    local quantised_note = scale.note_at_index(carved_scale, note_index)
    --print(quantised_note)

    -- include octaves from provided cv value in octave offset
    local octave_offset_notes = (math.floor(note / 12 + octave_offset) or 0) * 12

    return quantised_note + octave_offset_notes
end
