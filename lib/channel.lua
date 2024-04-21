local scale = include("lib/scale")

local Channel = {}

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
    self.trigger_ready = true
    self:play_note()
    self.observer:notify(source, "trigger", is_high)
end

function Channel:note_event(raw_note)
    local source = "channel_" .. self.id
    local quant_note = self:quantise_note(raw_note)
    if quant_note ~= self.note then
        self.note = quant_note
        self.observer:notify(source, "note", quant_note)
    end
    self.note_ready = true
    self:play_note()
end

function Channel:init_params(nb)
    params:add_separator("channel " .. self.id)
    params:add_number("channel_" .. self.id .. "_root_offset", "root offset", -11, 11, 0)
    params:add_number("channel_" .. self.id .. "_note_offset", "note offset", 0, 11, 0)
    params:add_number("channel_" .. self.id .. "_octave_offset", "octave offset", 0, 7, 3)
    params:add_number("channel_" .. self.id .. "_carve", "carve", 0, 5, 0)
    params:add_number("channel_" .. self.id .. "_chance", "chance", 0, 100, 100)
    nb:add_param("channel_" .. self.id .. "_output", "output")
end

function Channel:get_param(param_name)
    local param_id = "channel_" .. self.id .. "_" .. param_name
    return params:get(param_id)
end

function Channel:play_note()
    if self.note_ready and self.trigger_ready then
        self.note_ready = false
        self.trigger_ready = false
        local player = params:lookup_param("channel_" .. self.id .. "_output"):get_player()
        -- TODO: velocity and duration params
        player:play_note(self.note, 0.5, 0.2)
    end
end

function Channel:quantise_note(note)
    local note_offset = self:get_param("note_offset")
    local octave_offset = self:get_param("octave_offset")
    local carved_scale = self:get_carved_scale()

    -- assumes "index" quantisation type, where the unquantised note is used as an index to the scale note
    -- TODO: "nearest" quantisation type
    local clamped_note = note % 12
    local note_index = clamped_note + 1 + note_offset
    local quantised_note = scale.note_at_index(carved_scale, note_index)

    -- include octaves from provided note in octave offset
    local octave_offset_notes = (math.floor(note / 12 + octave_offset) or 0) * 12

    return quantised_note + octave_offset_notes
end

function Channel:get_root_note()
    local root_index = params:get("global_root")
    local root_offset = self:get_param("root_offset")
    return scale.circle_of_fifths_at(root_index + root_offset)
end

function Channel:get_carved_scale()
    local root_note = self:get_root_note()
    local scale_type = params:get("global_scale_type")
    local carve_amount = self:get_param("carve")
    return scale.carved_scale(root_note, scale_type, carve_amount)
end

return Channel
