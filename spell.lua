SPELL_SLEEP = {
  name = "sleep",
  level = 1,
  range = "all_enemies",
  effects = {
    { type = "set_sleep" }
  }
}

SPELL_FIRE = {
  name = "fire",
  level = 1,
  range = "single_enemy",
  effects = {
    { type = "overlay_animation", animation = ANIMATION_FIRE },
    { type = "damage", power = 3 }
  }
}