local Kria = {}

function Kria.enable(observer)
    crow.ii.kria.event = function(event, cv_value)
        -- TODO: is this necessary?
        channel = event.name == "cv" and event.arg + 1 or event.arg
        observer:notify("kria", event.name, { channel = channel, value = cv_value })
    end
end

function Kria.disable()
    crow.ii.kria.event = function() end
end

function Kria.get(event, channel)
    channel = event == "cv" and channel - 1 or channel
    crow.ii.kria.get(event, channel)
end

return Kria
