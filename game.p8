pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
MESSAGE_DUR = 0.75
FLASH_DUR = 0.25

TARGET_TABLE = {
  melee = {
    [4] = { 0.4, 0.3, 0.15, 0.15 },
    [3] = { 0.5, 0.3, 0.2 },
    [2] = { 0.6, 0.4 },
    [1] = { 1.0 }
  },
  uniform = {
    [4] = { 0.25, 0.25, 0.25, 0.25 },
    [3] = { 0.33, 0.33, 0.34 },
    [2] = { 0.5, 0.5 },
    [1] = { 1.0 }
  }
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

function combatant_row(combatant)
  return combatant.type == "player" and 1
      or (9 - combatant.position) % 3 + 1
end

function combatant_col(combatant)
  return combatant.type == "player" and combatant.position
      or flr((9 - combatant.position) / 3) + 1
end

function combatant_select_player_target(players, distribution)
  distribution = distribution or "uniform"
  local table = TARGET_TABLE[distribution][#players]

  -- random int from 1 to 4
  local r = flr(rnd(4)) + 1
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

function warrior_new(name, position)
  local sprite = 1
  local hp = 10
  local strength = 1
  return combatant_new("player", name, sprite, position, hp, strength)
end

function goblin_new(position)
  local sprite = 2
  local hp = 3
  local strength = -1
  local me = combatant_new("enemy", "goblin", sprite, position, hp, strength)
  me.behavior = goblin_behavior
  return me
end

function goblin_behavior(goblin, players, enemies)
  local target = combatant_select_player_target(players, "melee")

  local effects = {
    { type = "attack", attacker = goblin, target = target }
  }

  return effects
end

player1 = warrior_new("bart", 1)
player2 = warrior_new("vlad", 2)
player3 = warrior_new("lena", 3)
player4 = warrior_new("zara", 4)
enemy1 = goblin_new(1)
enemy2 = goblin_new(2)
enemy3 = goblin_new(3)
enemy4 = goblin_new(4)
enemy5 = goblin_new(5)

players = {
  player1,
  player2,
  player3,
  player4
}

enemies = {
  enemy1,
  enemy2,
  enemy3,
  enemy4,
  enemy5
}

combatants = {}

state = "start"
t0 = 0

function _init()
  for player in all(players) do
    add(combatants, player)
  end

  for enemy in all(enemies) do
    add(combatants, enemy)
  end

  active = combatants[1]
  state = "start"
  t0 = time()
  message = "enemies appear!"
end

function _update()
  if state == "start" and time() - t0 > MESSAGE_DUR then
    state = "player_turn"
    message = active.name .. "'s turn"
  elseif state == "player_turn" and btnp(4) then
    targets = {}
    for enemy in all(enemies) do
      if enemy.position <= 3 then
        add(targets, enemy)
      end
    end
    target_position = 1
    message = "select target: " .. targets[target_position].name
    state = "single_target_select"
  elseif state == "single_target_select" and btnp(2) then
    target_position = (target_position % #targets) + 1
    message = "select target: " .. targets[target_position].name
  elseif state == "single_target_select" and btnp(3) then
    target_position = target_position - 1
    if target_position < 1 then
      target_position = #targets
    end
    message = "select target: " .. targets[target_position].name
  elseif state == "single_target_select" and btnp(4) then
    local target = targets[target_position]
    local effect = { type = "attack", attacker = active, target = target }
    effects = { effect }
    animations = { animation_flash_new(active) }
    t0 = 0
    dur = MESSAGE_DUR
    state = "exec_effects"
  elseif state == "single_target_select" and btnp(5) then
    state = "player_turn"
    message = active.name .. "'s turn"
  elseif state == "exec_effects" and time() - t0 > dur and #effects == 0 then
    state = "end_turn"
    message = ""
  elseif state == "exec_effects" and time() - t0 > dur then
    execute_effect(effects)
  elseif state == "end_turn" and #enemies == 0 then
    state = "victory"
    message = "victory!"
  elseif state == "end_turn" and #players == 0 then
    state = "defeat"
    message = "defeat..."
  elseif state == "end_turn" then
    collapse_column(enemies)
    del(combatants, active)
    add(combatants, active)
    active = combatants[1]
    if active.type == "player" then
      state = "player_turn"
      message = active.name .. "'s turn"
    else
      effects = active.behavior(active, players, enemies)
      animations = { animation_flash_new(active) }
      t0 = time()
      dur = MESSAGE_DUR
      state = "exec_effects"
      message = active.name .. "'s turn"
    end
  elseif state == "enemy_turn" then
  end
end

function execute_effect(effects)
  local effect = effects[1]
  del(effects, effect)

  if effect.type == "attack" then
    local power = effect.attacker.strength
    local new_effect = { type = "damage", target = effect.target, power = power }
    message = effect.attacker.name .. " attacks"
    t0 = time()
    dur = MESSAGE_DUR
    add(effects, new_effect)
  elseif effect.type == "damage" then
    local damage = compute_damage(effect.power)
    effect.target.hp -= damage
    message = tostring(damage) .. " damage"
    t0 = time()
    dur = MESSAGE_DUR

    if effect.target.hp <= 0 then
      local new_effect = { type = "kill", target = effect.target }
      add(effects, new_effect)
    end
  elseif effect.type == "kill" then
    del(enemies, effect.target)
    del(players, effect.target)
    del(combatants, effect.target)
    message = effect.target.name .. " is defeated!"
    t0 = time()
    dur = MESSAGE_DUR
  end
end

function collapse_column(enemies)
  local col1_empty = true

  for enemy in all(enemies) do
    local pos = enemy.position
    if pos == 1 or pos <= 3 then
      col1_empty = false
      break
    end
  end

  if col1_empty then
    for enemy in all(enemies) do
      enemy.position -= 3
    end
  end
end

function compute_damage(power)
  local roll = flr(rnd(4)) + 1
  return max(1, power + roll)
end

function _draw()
  cls(2)
  draw_message(message)
  draw_players(players)
  draw_enemies(enemies)
  draw_player_stats(players)

  if state == "player_turn" then
    draw_menu(active)
  elseif state == "single_target_select" then
    draw_enemy_pointer(targets[target_position])
  end
end

function draw_message(text)
  local ox, oy = 4, 18
  local w, h = 118, 12

  rectfill(ox, oy, ox + w, oy + h, 0)
  rect(ox, oy, ox + w, oy + h, 7)
  print(text, ox + 4, oy + 4, 7)
end

function draw_players(players)
  local ox, oy = 90, 32
  local w, h = 32, 48
  local player_x, player_y = ox + 6, oy + 6

  rectfill(ox, oy, ox + w, oy + h, 0)
  rect(ox, oy, ox + w, oy + h, 7)

  for player in all(players) do
    local x = player_x + (player.position - 1) * 4
    local y = player_y + (player.position - 1) * 10
    spr(player.sprite, x, y)
  end
end

function draw_enemies(enemies)
  local ox, oy = 4, 32
  local w, h = 84, 48
  local enemy_x, enemy_y = ox, oy + 8

  rectfill(ox, oy, ox + w, oy + h, 0)
  rect(ox, oy, ox + w, oy + h, 7)

  for enemy in all(enemies) do
    local col = combatant_col(enemy)
    local row = combatant_row(enemy)
    local x = enemy_x + col * 24
    local y = enemy_y + (row - 1) * 12
    spr(enemy.sprite, x, y)
  end
end

function draw_enemy_pointer(enemy)
  local ox, oy = 4, 32
  local enemy_x, enemy_y = ox, oy + 8
  local col = combatant_col(enemy)
  local row = combatant_row(enemy)
  local x = enemy_x + col * 24 - 8
  local y = enemy_y + (row - 1) * 12
  spr(16, x, y + 2)
end

function draw_player_stats(players)
  local ox, oy = 4, 82
  local w, h = 28, 20

  for player in all(players) do
    local x = ox + (player.position - 1) * (w + 2)
    local y = oy
    local text_x = x + 4
    local name_y = y + 4
    local hp_y = name_y + 8
    rectfill(x, y, x + w, y + h, 0)
    rect(x, y, x + w, y + h, 7)
    print(player.name, text_x, name_y, 7)
    print("hp " .. player.hp, text_x, hp_y, 8)
  end
end

function draw_menu(player)
  local ox, oy = 8, 36
  local w, h = 60, 40
  local x, y = ox + 4, oy + 4

  rectfill(ox, oy, ox + w, oy + h, 0)
  rect(ox, oy, ox + w, oy + h, 7)

  print(player.name, x, y, 7)
  y += 10
  spr(16, x, y)
  print("attack", x + 8, y, 7)
  y += 8
  print("command", x + 8, y, 5)
  y += 8
  print("item", x + 8, y, 5)
end

function draw_sprite(sprite, x, y, tint)
  if tint then
    for i = 0, 15 do
      pal(i, tint)
    end
  end
  spr(sprite, x, y)
  pal()
end

function animation_flash_new(target)
  return {
    type = "flash",
    target = target,
    color = 7,
    dur = FLASH_DUR,
    t0 = time()
  }
end

__gfx__
0000000070ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000070ff00000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700708880000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000f850f00004bb40700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000660f000b44440700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000440000b02200b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060060000b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000040004000400400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
