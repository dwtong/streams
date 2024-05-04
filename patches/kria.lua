local kria = include("lib/devices/kria")

return function(observer, channels)
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
                kria.get("cv", i)
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

    -- channel 3 follows channel 2
    observer:add_listener("channel", "trigger", function(event)
        if event.channel == 2 then
            channels[3]:trigger_event(event.value)
        end
    end)
    observer:add_listener("channel", "note", function(event)
        if event.channel == 2 then
            channels[3]:note_event(event.value)
        end
    end)

    -- channel 4 samples channel 1 every fourth beat
    clock.run(function()
        while true do
            channels[4]:trigger_event(true)
            clock.run(function()
                clock.sleep(0.1)
                channels[4]:trigger_event(false)
            end)
            clock.sync(4)
        end
    end)
    observer:add_listener("channel", "note", function(event)
        if event.channel == 1 then
            channels[4]:note_event(event.value)
        end
    end)
end
