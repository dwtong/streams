local scale = include("lib/scale")

local Channel = {}

local quantise_modes = { "none", "nearest", "octave", "index" }

function Channel:new(id, observer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.id = id
    o.observer = observer
    return o
end

function Channel:trigger_event(is_high)
    self.observer:notify("channel", "trigger", { channel = self.id, value = is_high })
    if is_high then
        self.trigger_ready = true
        self.trigger_high = true
        self:play_note()
    else
        clock.run(function()
            clock.sleep(0.1)
            self.trigger_high = false
        end)
    end
end

function Channel:note_event(unquantised_note)
    local note = self:quantise_note(unquantised_note)
    self.next_note = note
    self.note_ready = true
    self:play_note()

    self.observer:notify("channel", "note", { channel = self.id, value = note })
end

function Channel:init_params(nb)
    params:add_separator("channel " .. self.id)
    params:add_option("channel_" .. self.id .. "_quantise_mode", "quantise mode", quantise_modes, 4)
    params:add_number("channel_" .. self.id .. "_root_offset", "root offset", -11, 11, 0)
    params:add_number("channel_" .. self.id .. "_note_offset", "note offset", 0, 11, 0)
    params:add_number("channel_" .. self.id .. "_octave_offset", "octave offset", -3, 4, 0)
    params:add_number("channel_" .. self.id .. "_carve", "carve", 0, 5, 0)
    params:add_number("channel_" .. self.id .. "_chance", "chance", 0, 100, 100)
    nb:add_param("channel_" .. self.id .. "_output", "output")
end

function Channel:get_param(param_name)
    local param_id = "channel_" .. self.id .. "_" .. param_name
    return params:get(param_id)
end

function Channel:play_note()
    if not self.note_ready or not self.trigger_ready then
        return
    end
    self.note_ready = false
    self.trigger_ready = false
    self.note = self.next_note
    local player = params:lookup_param("channel_" .. self.id .. "_output"):get_player()
    -- TODO: velocity and duration params
    player:play_note(self.note, 0.5, 0.2)
end

function Channel:quantise_note(note)
    local quantise_mode = quantise_modes[self:get_param("quantise_mode")]
    local octave_offset = self:get_octave()
    local clamped_note = note % 12

    if quantise_mode == "none" then
        return note
    elseif quantise_mode == "nearest" then
        -- TODO: nearest mode not implemented
        -- see `musicutil.snap_note_to_array`
        return note
    elseif quantise_mode == "octave" then
        return clamped_note + octave_offset
    elseif quantise_mode == "index" then
        local note_offset = self:get_param("note_offset")
        local carved_scale = self:get_carved_scale()
        local note_index = clamped_note + 1 + note_offset
        local quantised_note = scale.note_at_index(carved_scale, note_index)
        -- TODO: should we do this in other quantise modes?
        -- include octaves from provided note in octave offset
        local octave_offset_notes = (math.floor(note / 12 + octave_offset) or 0) * 12

        return quantised_note + octave_offset_notes
    end
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

function Channel:get_octave()
    return self:get_param("octave_offset") + DEFAULT_OCTAVE_OFFSET
end

return Channel
