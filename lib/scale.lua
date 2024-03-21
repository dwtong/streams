local Scale = {}

local carve = {
  -- 5 note scales (pentatonic)
  [5] = { 1, 4, 2, 5, 3 },
  -- 7 note scales
  [7] = { 1, 5, 3, 7, 2, 6, 4 },
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
  else
    return (index + 6) % 12
  end
end

function Scale.circle_of_fifths_names()
  local notes = {}
  for i = 1, 12 do
    note_num = Scale.circle_of_fifths_at(i)
    notes[i] = musicutil.note_num_to_name(note_num)
  end
  return notes
end

return Scale
