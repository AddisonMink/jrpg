local ENEMY_TARGET_TABLE = {
  melee = {
    [4] = { 40, 30, 15, 15 },
    [3] = { 50, 30, 20 },
    [2] = { 60, 40 },
    [1] = { 100 }
  },
  uniform = {
    [4] = { 25, 25, 25, 25 },
    [3] = { 33, 33, 34 },
    [2] = { 50, 50 },
    [1] = { 100 }
  }
}

local function enemy_find_target(players, distribution)
  distribution = distribution or "uniform"
  local table = ENEMY_TARGET_TABLE[distribution][#players]

  local r = rnd(99) + 1
  local cum_prob = 0
  local target = nil
  for i = 1, #table do
    cum_prob += table[i]
    if r <= cum_prob then
      target = players[i]
      break
    end
  end

  return target or players[#players]
end

function enemy_basic_attack(me, enemies, players)
  local target = enemy_find_target(players, "melee")

  return {
    { type = "flash", target = me, color = 7 },
    { type = "attack", attacker = me, target = target }
  }
end

function goblin_new(position)
  return {
    type = "enemy",
    name = "goblin",
    sprite = 2,
    position = position,
    hp = 3,
    hp_max = 3,
    strength = -1,
    behavior = enemy_basic_attack
  }
end

function hobgoblin_new(position)
  return {
    type = "enemy",
    name = "hobgoblin",
    sprite = 11,
    position = position,
    hp = 5,
    hp_max = 5,
    strength = 1,
    behavior = function(me, enemies, players)
      local allies_asleep = false
      for enemy in all(enemies) do
        if enemy.asleep then
          allies_asleep = true
          break
        end
      end

      local in_back_row = me.position > 3

      if allies_asleep then
        return {}
      elseif in_back_row then
        return {}
      else
        return enemy_basic_attack(me, enemies, players)
      end
    end
  }
end

function skeleton_new(position)
  return {
    type = "enemy",
    name = "skeleton",
    sprite = 4,
    position = position,
    hp = 2,
    hp_max = 2,
    strength = 0,
    behavior = enemy_basic_attack,
    undead = true
  }
end