local Txo = {
    param = {
        values = {},
    },
}

function Txo.init()
    print("init txo")
    for i = 1, 4 do
        -- TODO: add to params
        crow.ii.txo.env_act(i, 1)
        crow.ii.txo.cv(i, 8)
    end
end

function Txo.env_rise(channel, amount_ms)
    crow.ii.txo.env_att(channel, amount_ms)
end

function Txo.env_fall(channel, amount_ms)
    crow.ii.txo.env_dec(channel, amount_ms)
end

function Txo.env_trigger(channel)
    crow.ii.txo.env_trig(channel)
end

return Txo
