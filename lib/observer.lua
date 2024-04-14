local Observer = {
    listener_fns = {},
}

function Observer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Observer:add_listener(source, event_type, callback_fn)
    local listener_fns = self:find_listener_fns(source, event_type)
    table.insert(listener_fns, callback_fn)
end

function Observer:find_listener_fns(source, event_type)
    if self.listener_fns[source] == nil then
        self.listener_fns[source] = {}
    end
    if self.listener_fns[source][event_type] == nil then
        self.listener_fns[source][event_type] = {}
    end
    return self.listener_fns[source][event_type]
end

function Observer:notify(source, event_type, data)
    local listener_fns = self:find_listener_fns(source, event_type)
    for _, listener_fn in pairs(listener_fns) do
        listener_fn(data)
    end
end

return Observer
