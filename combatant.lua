-- #region enemy targeting functions
ENEMY_TARGET_TABLE = {
  melee = {
    [3] = { 50, 30, 20 },
    [2] = { 60, 40 },
    [1] = { 100 }
  },
  uniform = {
    [3] = { 33, 33, 34 },
    [2] = { 50, 50 },
    [1] = { 100 }
  }
}

function enemy_select_target(distribution, players)
  local table = ENEMY_TARGET_TABLE[distribution][#players]
  local roll = rnd(100)
  local cumulative = 0

  for i = 1, #table do
    cumulative += table[i]
    if roll < cumulative then
      return players[i]
    end
  end
  return players[#players]
end
-- #endregion

function warrior_new(name)
  return {
    type = "player",
    class = "warrior",
    name = name,
    animation = {
      animation = ANIMATION_WARRIOR_IDLE,
      t0 = time()
    },
    hp = { current = 10, max = 10 },
    -- player-only stats
    animations = {
      idle = ANIMATION_WARRIOR_IDLE,
      attack = ANIMATION_WARRIOR_ATTACK,
      item = ANIMATION_WARRIOR_ITEM
    },
    strength = 1
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
    hp = { current = 6, max = 6 },
    spell_uses = { 2 },
    spells = { SPELL_FIRE, SPELL_SLEEP },
    -- player-only stats
    animations = {
      idle = ANIMATION_WIZARD_IDLE,
      attack = ANIMATION_WIZARD_ATTACK,
      item = ANIMATION_WIZARD_ITEM
    },
    command = "spell",
    strength = -1
  }
end

function elf_new(name)
  return {
    type = "player",
    class = "elf",
    name = name,
    animation = {
      animation = ANIMATION_ELF_IDLE,
      t0 = time()
    },
    animations = {
      idle = ANIMATION_ELF_IDLE,
      attack = ANIMATION_ELF_ATTACK,
      item = ANIMATION_ELF_ITEM
    },
    hp = { current = 8, max = 8 }
  }
end

function goblin_new(position)
  return {
    type = "enemy",
    name = "goblin",
    animation = enemy_animation(0, 48, 16, 16),
    hp = { current = 5, max = 5 },
    position = position,
    -- enemy-only fields
    behavior = function(me, enemies, players)
      local target = enemy_select_target("melee", players)

      return {
        { type = "flash", target = me, color = 7 },
        { type = "message", text = me.name .. " attacks!" },
        { type = "damage", target = target, power = 0 }
      }
    end
  }
end