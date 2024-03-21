local Scale = {}

local carve_priorities = {
  -- 5 note scales (pentatonic)
  [5] = { 1, 4, 2, 5, 3 },
  -- 7 note scales
  [7] = { 1, 5, 3, 7, 2, 6, 4 },
  -- TODO: handle other scale sizes
}

function Scale.scale_names()
  local scales = {}
  for i, scale in ipairs(musicutil.SCALES) do
    scales[i] = string.lower(scale.name)
  end

  return scales
end

function Scale.circle_of_fifths_at(index)
  index = (index - 1) % 12
  if index % 2 == 0 then
    return index
  end

  return (index + 6) % 12
end

function Scale.circle_of_fifths_names()
  local notes = {}
  for i = 1, 12 do
    note_num = Scale.circle_of_fifths_at(i)
    notes[i] = musicutil.note_num_to_name(note_num)
  end
  return notes
end

function Scale.carve_scale(scale_type, carve_amount)
  local scale_notes = musicutil.generate_scale(0, scale_type, 1)
  local carved_scale = {}

  for length, priorities in pairs(carve_priorities) do
    if #scale_notes - 1 == length then
      for i = 1, length - carve_amount do
        note_number = priorities[i]
        carved_scale[i] = scale_notes[note_number]
      end
    end
  end

  if #carved_scale == 0 then
    print("scale not supported by carve.")
    return scale_notes
  end

  table.sort(carved_scale)
  return carved_scale
end

return Scale
