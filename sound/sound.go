components {
  id: "sound"
  component: "/sound/sound.script"
}
embedded_components {
  id: "music"
  type: "sound"
  data: "sound: \"/assets/click.wav\"\n"
  "group: \"music\"\n"
  "gain: 0.5\n"
  ""
}
embedded_components {
  id: "click"
  type: "sound"
  data: "sound: \"/assets/click.wav\"\n"
  "group: \"metronome\"\n"
  "gain: 5.0\n"
  ""
}
embedded_components {
  id: "beep"
  type: "sound"
  data: "sound: \"/assets/beep.wav\"\n"
  "group: \"metronome\"\n"
  "speed: 2.0\n"
  ""
}
