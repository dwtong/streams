local Crow = {}

function Crow.enable(observer)
    for channel = 1, 2 do
        crow.input[channel].mode("change")
        crow.input[channel].change = function(is_high)
            observer:notify("crow", "trigger", { channel = channel, value = is_high })
        end
    end
end

function Crow.disable()
    crow.input[channel].change = function() end
end

return Crow
