local Jf = {
  voice_count = 6,
}

local last_voice = 1

function Jf.init()
  print("init crow")
  crow.ii.jf.mode(1)
end

function Jf.play_note(pitch_volts, velocity_volts, voice)
  if voice == nil then
    voice = last_voice % Jf.voice_count + 1
    last_voice = voice
  end

  crow.ii.jf.play_voice(voice, pitch_volts, velocity_volts)
end

return Jf
