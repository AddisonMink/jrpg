ANIMATION_SLEEP_ID = 104
ANIMATION_FIRE_ID = 128
ANIMATION_BANISH_ID = 160
ANIMATION_HEAL_ID = 136

SPELL_FIRE = {
  name = "fire",
  level = 1,
  range = "single",
  effects = {
    { type = "animation", id = ANIMATION_FIRE_ID },
    { type = "damage", power = 3 }
  }
}

SPELL_SLEEP = {
  name = "sleep",
  level = 1,
  range = "all",
  effects = {
    { type = "animation", id = ANIMATION_SLEEP_ID },
    { type = "sleep" }
  }
}

SPELL_BANISH = {
  name = "banish",
  level = 1,
  range = "all",
  effects = {
    { type = "animation", id = ANIMATION_BANISH_ID },
    { type = "banish", power = 2 }
  }
}

SPELL_HEAL = {
  name = "heal",
  level = 1,
  range = "ally",
  effects = {
    { type = "animation", id = ANIMATION_HEAL_ID },
    { type = "heal", power = 5 }
  }
}