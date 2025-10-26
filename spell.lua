ANIM_FIRE = {
  type = "overlay",
  frames = { 17, 18, 19 },
  fps = 12,
  dur = 1.0
}

ANIM_SLEEP = {
  type = "overlay",
  frames = { 20, 21, 22, 21 },
  fps = 6,
  dur = 0.75
}

ANIM_SPARKLE = {
  type = "overlay",
  frames = { 24, 25, 26 },
  fps = 6,
  dur = 0.75
}

SPELL_FIRE = {
  name = "fire",
  level = 1,
  range = "single",
  effects = function(caster)
    return {
      { type = "use_spell", name = "fire", target = caster, level = 1 },
      { type = "overlay", animation = ANIM_FIRE },
      { type = "damage", power = 5 }
    }
  end
}

SPELL_SLEEP = {
  name = "sleep",
  level = 1,
  range = "all_enemies",
  effects = function(caster)
    return {
      { type = "use_spell", name = "sleep", target = caster, level = 1 },
      { type = "overlay", animation = ANIM_SLEEP },
      { type = "set_sleep" }
    }
  end
}

SPELL_HEAL = {
  name = "heal",
  level = 1,
  range = "single_ally",
  effects = function(caster)
    return {
      { type = "use_spell", name = "heal", target = caster, level = 1 },
      { type = "overlay", animation = ANIM_SPARKLE },
      { type = "heal", power = 1 }
    }
  end
}

SPELL_BANISH = {
  name = "banish",
  level = 1,
  range = "all_enemies",
  effects = function(caster)
    return {
      { type = "use_spell", name = "banish", target = caster, level = 1 },
      { type = "overlay", animation = ANIM_SPARKLE },
      { type = "banish", power = 3 }
    }
  end
}