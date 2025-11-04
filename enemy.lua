TARGET_DISTRIBUTIONS = {
  melee = {
    [3] = { 0.5, 0.3, 0.2 },
    [2] = { 0.7, 0.3 },
    [1] = { 1.0 }
  },
  uniform = {
    [3] = { 0.33, 0.33, 0.34 },
    [2] = { 0.5, 0.5 },
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

function basic_attack(me, players)
  local target = select_enemy_target("melee", players)
  return {
    { type = "flash", target = me, color = 7 },
    { type = "banner_message", text = me.name .. " attacks!" },
    { type = "damage", target = target, power = me.strength }
  }
end

function goblin_new()
  return {
    type = "goblin",
    name = "goblin",
    hp_max = 5,
    strength = 6,
    sleep_resist_max = 4,
    behavior = function(me, enemies, players)
      return basic_attack(me, players)
    end
  }
end

function hobgoblin_new()
  return {
    type = "hobgoblin",
    name = "hobgoblin",
    hp_max = 30,
    strength = 10,
    sleep_resist_max = 6,
    spawn_list = { { type = "goblin" } },
    behavior = function(me, enemies, players)
      if #enemies < 4 then
        return {
          { type = "flash", target = me, color = 8 },
          { type = "banner_message", text = me.name .. " calls for help!" },
          { type = "animation", target = me, id = ANIMATION_SHOUT_ID },
          { type = "spawn_enemy", enemy_type = "goblin" }
        }
      else
        return basic_attack(me, players)
      end
    end
  }
end

function witch_new()
  return {
    type = "witch",
    name = "witch",
    hp_max = 20,
    strength = 0,
    sleep_resist_max = 8,
    behavior = function(me, enemies, players)
      if rnd(100) < 66 then
        local target = select_enemy_target("uniform", players)

        local effects = {
          { type = "flash", target = me, color = 9 },
          { type = "banner_message", text = me.name .. " casts fire" }
        }

        for e in all(SPELL_FIRE.effects) do
          local effect = copy_table(e)
          effect.target = target
          add(effects, effect)
        end

        return effects
      else
        local effects = {
          { type = "flash", target = me, color = 9 },
          { type = "banner_message", text = me.name .. " casts sleep" }
        }

        for target in all(players) do
          for e in all(SPELL_SLEEP.effects) do
            local effect = copy_table(e)
            effect.target = target
            add(effects, effect)
          end
        end

        return effects
      end
    end
  }
end

function wolf_new()
  return {
    type = "wolf",
    name = "wolf",
    hp_max = 15,
    strength = 8,
    sleep_resist_max = 4,
    behavior = function(me, enemies, players)
      local allies_asleep_or_not_buffed = false
      for e in all(enemies) do
        if e.sleep or not e.might then
          allies_asleep_or_not_buffed = true
          break
        end
      end

      local howl = allies_asleep_or_not_buffed and rnd(0, 100) < 50

      if howl then
        local effects = {
          { type = "flash", target = me, color = 9 },
          { type = "banner_message", text = me.name .. " howls!" },
          { type = "animation", target = me, id = ANIMATION_SHOUT_ID }
        }

        for e in all(enemies) do
          add(effects, { type = "might", target = e })
          add(effects, { type = "clear_status", target = e })
        end

        return effects
      else
        return basic_attack(me, players)
      end
    end
  }
end

function zombie_new()
  return {
    type = "zombie",
    name = "zombie",
    hp_max = 20,
    strength = 10,
    undead = true,
    sleep_resist_max = 0,
    behavior = function(me, enemies, players)
      return basic_attack(me, players)
    end
  }
end

SPAWN_FUNCTION_MAP = {
  goblin = goblin_new,
  hobgoblin = hobgoblin_new,
  witch = witch_new,
  wolf = wolf_new,
  zombie = zombie_new
}