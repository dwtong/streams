-- streams

DEFAULT_OCTAVE_OFFSET = 4 -- middle C

local musicutil = require("musicutil")

local nb = include("lib/nb/lib/nb")
local scale = include("lib/scale")

local Observer = include("lib/observer")
local Channel = include("lib/channel")

local devices = {
    crow = include("lib/devices/crow"),
    kria = include("lib/devices/kria"),
}

channels = {}
local is_screen_dirty = false

function init()
    local observer = Observer:new()
    for device_name, device in pairs(devices) do
        device.enable(observer)
        print("enabled device: " .. device_name)
    end

    nb:init()
    init_global_params()

    for i = 1, 4 do
        local channel = Channel:new(i, observer)
        channel:init_params(nb)
        table.insert(channels, channel)
    end

    observer:add_listener("channel", "note", function()
        is_screen_dirty = true
    end)

    -- channels 1 & 2:
    -- trigger device: crow in 1 & 2
    -- note device: kria cv 1 & 2
    for i = 1, 2 do
        local channel = channels[i]
        observer:add_listener("crow", "trigger", function(crow_channel, is_high)
            if crow_channel == i then
                channel:trigger_event(is_high)
            end
        end)
        observer:add_listener("kria", "cv", function(kria_channel, cv_value)
            if kria_channel == i then
                local note = volts_to_note(cv_value)
                channel:note_event(note)
            end
        end)
        observer:add_listener("channel", "trigger", function(trigger_channel, is_high)
            if trigger_channel == i and is_high then
                devices.kria.get("cv", i)
            end
        end)
        observer:add_listener("channel", "note", function(note_channel, note)
            if note_channel == i then
                local player = params:lookup_param("channel_" .. channel.id .. "_output"):get_player()
                player:play_note(note, 0.5, 0.2)
            end
        end)
    end

    -- channel 3 samples channel 1 every fourth beat
    clock.run(function()
        while true do
            channels[3]:trigger_event(true)
            clock.sync(4)
        end
    end)
    observer:add_listener("channel", "note", function(note_channel, note)
        if note_channel == 1 then
            channels[3]:note_event(note)
        end
    end)

    nb:add_player_params()

    clock.run(function()
        while true do
            if is_screen_dirty then
                redraw()
            end
            clock.sleep(1 / 30)
        end
    end)
end

function redraw()
    screen.clear()
    screen.level(15)
    for i = 1, #channels do
        local channel = channels[i]
        local x = (i == 1 or i == 3) and 20 or 84
        local y = (i == 1 or i == 2) and 20 or 52
        local note = channel.note and musicutil.note_num_to_name(channel.note) or "x"
        screen.font_size(18)
        screen.move(x, y)
        screen.text(note)
        if channel.note then
            local offset = screen.text_extents(note) + 2
            screen.font_size(10)
            screen.move(x + offset, y)
            screen.text(channel:get_octave())
            screen.font_size(8)
            screen.move(x - 15, y - 3)
            screen.text(channel.note)
        end
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

function init_global_params()
    params:add_separator("global")
    params:add_option("global_scale_type", "scale", scale.scale_names(), 11)
    params:add_option("global_root", "root note", scale.circle_of_fifths_names(), 1)
end
