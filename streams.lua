-- streams

DEFAULT_OCTAVE_OFFSET = 4 -- middle C

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
    observer:add_listener("channel", "trigger", function()
        is_screen_dirty = true
    end)

    -- channels 1 & 2:
    -- trigger device: crow in 1 & 2
    -- note device: kria cv 1 & 2
    for i = 1, 2 do
        local channel = channels[i]

        -- 1: trigger at crow input fires channel trigger event
        observer:add_listener("crow", "trigger", function(event)
            if event.channel == i then
                channel:trigger_event(event.value)
            end
        end)
        -- 2: channel trigger event requests cv value from kria
        observer:add_listener("channel", "trigger", function(event)
            if event.channel == i and event.value == true then
                devices.kria.get("cv", i)
            end
        end)
        -- 3: kria returns cv value and fires channel note event
        observer:add_listener("kria", "cv", function(event)
            if event.channel == i then
                local note = volts_to_note(event.value)
                channel:note_event(note)
            end
        end)
    end

    -- channel 3 samples channel 1 every fourth beat
    clock.run(function()
        while true do
            channels[3]:trigger_event(true)
            clock.run(function()
                clock.sleep(0.1)
                channels[3]:trigger_event(false)
            end)
            clock.sync(4)
        end
    end)
    observer:add_listener("channel", "note", function(event)
        if event.channel == 1 then
            channels[3]:note_event(event.value)
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

    -- TESTING: hard coded presets
    clock.run(function()
        clock.sleep(1)
        params:set("channel_1_quantise_mode", 4) -- index
        params:set("channel_1_output", 10) -- jf poly
        params:set("nb_jf_poly_alloc_mode", 2) -- rotate
        params:set("channel_2_quantise_mode", 4) -- index
        params:bang()
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
            screen.move(x + offset, y)
            screen.font_size(10)
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
