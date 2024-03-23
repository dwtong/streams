local Jf = {}

local voice_count = 6
local last_voice = 1

function Jf.init()
  print("init jf")
  crow.ii.jf.mode(1)
  crow.ii.jf.transpose(-2)
end

function Jf.set_voice_count(new_count)
  voice_count = new_count
end

function Jf.play_note(pitch_volts, velocity_volts, voice)
  if voice == nil then
    voice = last_voice % voice_count + 1
    last_voice = voice
  end

  crow.ii.jf.play_voice(voice, pitch_volts, velocity_volts)
end

return Jf
