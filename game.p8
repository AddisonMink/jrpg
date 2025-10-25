pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include battle.lua

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

function combatant_new(type, name, sprite, position, hp, strength)
  return {
    type = type,
    name = name,
    sprite = sprite,
    position = position,
    hp_max = hp,
    hp = hp,
    strength = strength
  }
end

function warrior_new(name, position)
  local sprite = 1
  local hp = 10
  local strength = 1

  local command = {
    name = "guard",
    type = "command"
  }

  local me = combatant_new("player", name, sprite, position, hp, strength)
  me.command = command
  return me
end

function wizard_new(name, position)
  local sprite = 3
  local hp = 6
  local strength = -1
  local spell_uses = { 2 }

  local command = {
    name = "spell",
    type = "spell",
    spells = {
      SPELL_FIRE,
      SPELL_SLEEP
    }
  }

  local me = combatant_new("player", name, sprite, position, hp, strength)
  me.command = command
  me.spell_uses = spell_uses
  return me
end

function cleric_new(name, position)
  local sprite = 5
  local hp = 8
  local strength = 0
  local spell_uses = { 2 }

  local command = {
    name = "pray",
    type = "spell",
    spells = {
      SPELL_HEAL,
      SPELL_BANISH
    }
  }

  local me = combatant_new("player", name, sprite, position, hp, strength)
  me.command = command
  me.spell_uses = spell_uses
  return me
end

function goblin_new(position)
  local sprite = 2
  local hp = 3
  local strength = -1
  return combatant_new("enemy", "goblin", sprite, position, hp, strength)
end

function skeleton_new(position)
  local sprite = 4
  local hp = 2
  local strength = 0
  local me = combatant_new("enemy", "skeleton", sprite, position, hp, strength)
  me.undead = true
  return me
end

player1 = cleric_new("ana", 1)
player2 = wizard_new("vlad", 2)
enemy1 = goblin_new(1)
enemy2 = goblin_new(2)
enemy3 = skeleton_new(3)

players = {
  player1,
  player2
}

enemies = {
  enemy1,
  enemy2,
  enemy3
}

combatants = {}

state = "start"
t0 = 0

function _init()
  battle = battle_new(players, enemies)
end

function _update()
  battle:update()
end

function _draw()
  cls(2)
  battle:draw()
end

__gfx__
0000000070ff000000000000020cc000000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000070ff000000880000020fc000000077000004550000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007088800000088000020ccc00000076007000450000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000f850f00004bb40002fcc0c0000755660706950000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000660f000b444400002440f0000577000094750000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000440000b02200b000ccc000000600000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060060000b00b00000cccc00007060000004770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000040004000400400000400040070060000040999000000000000000000000000000000000000000000000000000000000000000000000000000000000
0060000000008000000000000000000000000000007e000000e00000000777700090000000900000090000000000000000000000000000000000000000000000
07777700000800000000000000000000007e000000000000000000000000070009a9000000000000000090000000000000000000000000000000000000000000
7777000000880000000080000000000007eee00070000e000e007e00000070009a7a9000900090900009a9000000000000000000000000000000000000000000
777600000089800000008800000000000eee2000e0000e200007eee00007777009a900a0000009a9909a7a900000000000000000000000000000000000000000
0000000000898800000888000000080000e200000000222e000eee207770000000900a7a00909a7a0009a9000000000000000000000000000000000000000000
00000000089798800088980000088000000007e000ee222e0000e20007000000000000a0000a09a900a090000000000000000000000000000000000000000000
000000000897798000897900008998000e000e200e0002e00000000077700000000a000000a7a0900a7a00000000000000000000000000000000000000000000
00000000009779000087798000879800000000000000000000000e000000000000000000000a000000a000000000000000000000000000000000000000000000
