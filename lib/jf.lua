local Jf = {}

function Jf.init()
  print("init crow")
  crow.ii.jf.mode(1)
end

function Jf.play_note(pitch, level, voice)
  if voice == nil then
    -- TODO: voice allocation
    crow.ii.jf.play_note(pitch, level)
  else
    crow.ii.jf.play_voice(voice, pitch, level)
  end
end

return Jf
