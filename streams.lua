-- streams

DEFAULT_OCTAVE_OFFSET = 4 -- middle C
CHANNEL_COUNT = 4
AUTOSAVE = true

local musicutil = require("musicutil")

local nb = include("lib/nb/lib/nb")
scale = include("lib/scale")

local Observer = include("lib/observer")
local Channel = include("lib/channel")

local devices = {
    crow = include("lib/devices/crow"),
    kria = include("lib/devices/kria"),
}

channels = {}
local is_screen_dirty = false

function cleanup()
    if AUTOSAVE then
        params:write()
    end
end

function init()
    local observer = Observer:new()
    for device_name, device in pairs(devices) do
        device.enable(observer)
        print("enabled device: " .. device_name)
    end

    observer:add_listener("channel", "note", function()
        is_screen_dirty = true
    end)
    observer:add_listener("channel", "trigger", function()
        is_screen_dirty = true
    end)

    nb:init()
    init_global_params()

    params:add_separator("transformations")
    for i = 1, CHANNEL_COUNT do
        local channel = Channel:new(i, observer)
        channel:init_params()
        table.insert(channels, channel)
    end

    params:add_separator("outputs")
    for i = 1, #channels do
        nb:add_param("channel_" .. i .. "_output", "channel " .. i)
    end
    nb:add_player_params()

    clock.run(function()
        while true do
            if is_screen_dirty then
                redraw()
            end
            clock.sleep(1 / 30)
        end
    end)

    if AUTOSAVE then
        params:default()
    end

    -- init patch from patches directory
    include("patches/kria")(observer, channels)
end

function redraw()
    screen.clear()
    for i = 1, #channels do
        local channel = channels[i]
        local x = (i == 1 or i == 3) and 20 or 84
        local y = (i == 1 or i == 2) and 20 or 52
        local note = channel.note and musicutil.note_num_to_name(channel.note) or "x"
        if channel:muted() then
            screen.level(1)
        else
            screen.level(15)
        end
        screen.font_size(18)
        screen.move(x, y)
        screen.text(note)
        if channel.note then
            local offset = screen.text_extents(note) + 2
            screen.move(x + offset, y)
            screen.font_size(10)
            -- FIXME: this does not include the "note" octave
            screen.text(channel:get_octave())
            screen.move(x - 15, y)
            screen.font_size(8)
            screen.text(channel.note)
        end
        if channel.trigger_high then
            screen.move(x - 15, y - 10)
            screen.font_size(15)
            screen.text(".")
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
    local root_order_options = { "circle of fifths", "chromatic" }
    params:add_separator("global")
    params:add_option("global_root", "root note", scale.circle_of_fifths_names(), 1)
    params:add_option("global_root_order", "root order", root_order_options, 1)
    params:add_option("global_scale_type", "scale", scale.scale_names(), 11)

    params:set_action("global_root_order", function(option_index)
        local param = params:lookup_param("global_root")
        local root_order_option = root_order_options[option_index]
        if root_order_option == "chromatic" then
            param.options = scale.chromatic_names()
        else
            param.options = scale.circle_of_fifths_names()
        end
        param.selected = 1
        _menu.rebuild_params()
    end)
    params:set_action("global_scale_type", function(scale_type)
        local carve_max = scale.length(scale_type) - 1
        for i = 1, #channels do
            local param = params:lookup_param("channel_" .. i .. "_carve")
            param.max = carve_max
        end
        _menu.rebuild_params()
    end)
end
