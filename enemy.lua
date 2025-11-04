TARGET_DISTRIBUTIONS = {
  melee = {
    [3] = { 0.5, 0.3, 0.2 },
    [2] = { 0.7, 0.3 },
    [1] = { 1.0 }
  }
}

function select_enemy_target(dist, players)
  local distribution = TARGET_DISTRIBUTIONS[dist][#players]
  local r = rnd(100)
  local acc = 0
  for i = 1, #distribution do
    acc += distribution[i] * 100
    if r < acc then
      return players[i]
    end
  end
end

function basic_attack(me, players, power)
  local target = select_enemy_target("melee", players)
  return {
    { type = "flash", target = me, color = 7 },
    { type = "banner_message", text = me.name .. " attacks!" },
    { type = "damage", target = target, power = power }
  }
end

function goblin_new()
  return {
    type = "goblin",
    name = "goblin",
    hp_max = 5,
    behavior = function(me, enemies, players)
      return basic_attack(me, players, 6)
    end
  }
end

function hobgoblin_new()
  return {
    type = "hobgoblin",
    name = "hobgoblin",
    hp_max = 30,
    spawn_list = { { type = "goblin" } },
    behavior = function(me, enemies, players)
      if #enemies < 4 then
        return {
          { type = "flash", target = me, color = 8 },
          { type = "banner_message", text = me.name .. " calls for help!" },
          { type = "spawn_enemy", enemy_type = "goblin" }
        }
      else
        return basic_attack(me, players, 8)
      end
    end
  }
end

function zombie_new()
  return {
    type = "zombie",
    name = "zombie",
    hp_max = 20,
    undead = true,
    behavior = function(me, enemies, players)
      return basic_attack(me, players, 10)
    end
  }
end

SPAWN_FUNCTION_MAP = {
  goblin = goblin_new,
  hobgoblin = hobgoblin_new,
  zombie = zombie_new
}