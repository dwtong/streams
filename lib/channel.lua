local Channel = {
    note = 0,
    note_ready = false,
    trigger_ready = false,
}

local play_note

function Channel:new(id, observer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.id = id
    o.observer = observer
    return o
end

function Channel:trigger_event(is_high)
    local source = "channel_" .. self.id
    print(source)
    play_note(self)
    self.observer:notify(source, "trigger", is_high)
end

function Channel:note_event(raw_note)
    local source = "channel_" .. self.id
    -- local quant_note = self:quantise_value(raw_note)
    local quant_note = raw_note * 10

    if quant_note ~= self.note then
        self.note = quant_note
        play_note(self)
        self.observer:notify(source, "note", quant_note)
    end
end

function play_note(channel)
    if channel.note_ready and channel.trigger_ready then
        print("play note " .. tostring(channel.note))
    end
end

return Channel

-- local scale = include("lib/scale")
-- local set_trigger_source, set_cv_source

-- function Channel:new(id)
--     -- o = o or {}
--     setmetatable({ id = id }, self)
--     self.__index = self
--     return o
-- end

-- function Channel:init_params(nb)
--     params:add_separator("channel " .. self.id)
--     params:add_option("channel_" .. self.id .. "_input_trigger", "input trigger", trigger_source_options, 1)
--     params:set_action("input_trigger_source_" .. i, function(source)
--         hooks.set_trigger_source(self.id, source)
--     end)
--     params:add_option("channel_" .. self.id .. "_input_cv_source", "input cv source", cv_source_options, 1)
--     params:set_action("channel_" .. self.id .. "_input_cv_source", function(source)
--         hooks.set_cv_source(self.id, source)
--     end)
--     params:add_number("channel_" .. self.id .. "_root_offset", "root offset", -11, 11, 0)
--     params:add_number("channel_" .. self.id .. "_note_offset", "note offset", 0, 11, 0)
--     params:add_number("channel_" .. self.id .. "_octave_offset", "octave offset", -3, 3, 0)
--     params:add_number("channel_" .. self.id .. "_carve", "carve", 0, 5, 0)
--     params:add_number("channel_" .. self.id .. "_chance", "chance", 0, 100, 100)

--     nb:add_param("output_channel_" .. i, "channel " .. i)
-- end

-- function Channel:get_param(name)
--     params:get(self.id .. name)
-- end

-- function Channel:get_root_note()
--     local root_index = params:get("global_root")
--     local root_offset = self:get_param("root_offset")
--     return scale.circle_of_fifths_at(root_index + root_offset)
-- end

-- function Channel:get_carved_scale()
--     local root_note = self:get_root_note()
--     local scale_type = params:get("global_scale_type")
--     local carve_amount = self:get_param("carve")
--     return scale.carved_scale(root_note, scale_type, carve_amount)
-- end

-- function Channel:quantise_note(note)
--     local note_offset = self:get_param("note_offset")
--     local octave_offset = self:get_param("octave_offset")
--     local carved_scale = self:get_carved_scale()

--     -- assumes "index" quantisation type, where the unquantised note is used as an index to the scale note
--     -- TODO: "nearest" quantisation type
--     local clamped_note = note % 12
--     local note_index = clamped_note + 1 + note_offset
--     local quantised_note = scale.note_at_index(carved_scale, note_index)

--     -- include octaves from provided note in octave offset
--     local octave_offset_notes = (math.floor(note / 12 + octave_offset) or 0) * 12

--     return quantised_note + octave_offset_notes
-- end
