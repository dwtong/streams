-- algae

local nb = include("lib/nb/lib/nb")
local scale = include("lib/scale")

local Observer = include("lib/observer")
local Channel = include("lib/channel")

local sources = {
    crow = include("lib/sources/crow"),
    kria = include("lib/sources/kria"),
}

local values = { 0, 0 }

function init()
    local observer = Observer:new()
    for source_name, source in pairs(sources) do
        source.enable(observer)
        print("enabled source: " .. source_name)
    end

    nb:init()
    init_global_params()

    for i = 1, 2 do
        local channel = Channel:new(i, observer)
        channel:init_params(nb)

        observer:add_listener("crow_" .. i, "trigger", function(is_high)
            channel:trigger_event(is_high)
        end)
        observer:add_listener("channel_" .. i, "trigger", function(is_high)
            if is_high then
                sources.kria.get("cv", i)
            end
        end)
        observer:add_listener("kria_" .. i, "cv", function(cv_value)
            local note = volts_to_note(cv_value)
            channel:note_event(note)
        end)
        observer:add_listener("channel_" .. i, "note", function(note)
            values[i] = note
            redraw()
        end)
    end

    nb:add_player_params()
end

function redraw()
    screen.clear()
    screen.level(15)
    screen.font_size(20)
    for i = 1, #values do
        screen.move(30, 22 * i)
        screen.text(tostring(values[i]))
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

function init_global_params()
    params:add_separator("global")
    params:add_option("global_scale_type", "scale", scale.scale_names(), 11)
    params:add_option("global_root", "root note", scale.circle_of_fifths_names(), 1)
end
