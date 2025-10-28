function warrior_new(name)
  return {
    type = "player",
    class = "warrior",
    name = name,
    animation = {
      animation = ANIMATION_WARRIOR_IDLE,
      t0 = time()
    },
    animations = {
      idle = ANIMATION_WARRIOR_IDLE,
      attack = ANIMATION_WARRIOR_ATTACK,
      item = ANIMATION_WARRIOR_ITEM
    },
    hp = { current = 10, max = 10 }
  }
end

function wizard_new(name)
  return {
    type = "player",
    class = "wizard",
    name = name,
    animation = {
      animation = ANIMATION_WIZARD_IDLE,
      t0 = time()
    },
    animations = {
      idle = ANIMATION_WIZARD_IDLE,
      attack = ANIMATION_WIZARD_ATTACK,
      item = ANIMATION_WIZARD_ITEM
    },
    hp = { current = 6, max = 6 }
  }
end

function goblin_new(position)
  return {
    type = "enemy",
    name = "goblin",
    animation = enemy_animation(0, 48, 16, 16),
    hp = { current = 5, max = 5 },
    position = position
  }
end

function combatant_draw(combatant, x, y)
  local animation = combatant.animation.animation
  local t0 = combatant.animation.t0

  animation_draw(animation, x, y, t0)
end