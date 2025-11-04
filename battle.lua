-- #region constants
ANIMATION_FPS = 12
ANIMATION_ATTACK_OFFSETS = { 0, 2, 5 }
ANIMATION_ATTACK_X_OFFSETS = { -4, -12, -12 }
MESSAGE_DUR = 0.5
FLASH_DUR = 0.1
ANIMATION_DUR = 1.0 / ANIMATION_FPS * 3.0 * 2
-- #endregion

-- #region initialization
function load_battle(players, enemy_list)
  local player_sprite_ids = { 0, 32, 64 }
  local player_sprite_index = 1

  local enemy_sprite_ids = { 96, 98, 100, 102 }
  local enemy_sprite_index = 1

  -- get set of player types
  local player_types = {}
  for p in all(players) do
    player_types[p.type] = true
  end

  -- cache player sprites
  for pt, _ in pairs(player_types) do
    local sprite_id = player_sprite_ids[player_sprite_index]
    cache_player_sprite_data(pt, sprite_id)
    player_types[pt] = sprite_id
    player_sprite_index += 1
  end

  -- get set of enemy types
  local enemy_types = {}
  for e in all(enemy_list) do
    enemy_types[e] = true
    for e in all(e.spawn_list or {}) do
      enemy_types[e] = true
    end
  end

  -- cache enemy sprites
  for et, _ in pairs(enemy_types) do
    local sprite_id = enemy_sprite_ids[enemy_sprite_index]
    cache_enemy_sprite_data(et, sprite_id)
    enemy_types[et] = sprite_id
    enemy_sprite_index += 1
  end

  -- initialize players
  for p in all(players) do
    p.side = "player"
    p.sprite_id = player_types[p.type]
    p.state = "idle"
    p.state_started_at = time()
    p.hp = p.hp_max
    p.sleep_resist = p.sleep_resist_max

    p.commands = { { name = "attack", type = "attack" } }
    if p.special then
      add(p.commands, p.special)
    end
    add(p.commands, { name = "defend", type = "defend" })
  end

  -- build spawn dict for enemies
  local spawn_dict = {}
  for type, sprite_id in pairs(enemy_types) do
    spawn_dict[type] = { func = SPAWN_FUNCTION_MAP[type], sprite_id = sprite_id }
  end

  -- initialize enemies
  local position = 1
  local enemies = {}
  for e in all(enemy_list) do
    local enemy = spawn_enemy(spawn_dict[e], position)
    add(enemies, enemy)
    position += 1
  end

  -- initialize queue
  local queue = {}
  for p in all(players) do
    add(queue, p)
  end
  for e in all(enemies) do
    add(queue, e)
  end

  return {
    spawn_dict = spawn_dict,
    players = players,
    enemies = enemies,
    queue = queue,
    message = "enemies appear!",
    state = { type = "start", t0 = time() }
  }
end

function spawn_enemy(spawn_data, position)
  local f = spawn_data.func
  local sprite_id = spawn_data.sprite_id
  local enemy = f()
  enemy.sprite_id = sprite_id
  enemy.position = position
  enemy.hp = enemy.hp_max
  enemy.sleep_resist = enemy.sleep_resist_max
  enemy.side = "enemy"
  return enemy
end
-- #endregion

-- #region update
function update_battle(battle)
  if battle.state.type == "start" and time() - battle.state.t0 > MESSAGE_DUR then
    local next = battle.queue[1]

    battle.message = nil
    if next.side == "player" then
      battle.state = { type = "player_turn", index = 1 }
    else
      battle.state = { type = "enemy_turn" }
    end
    return
  end

  if battle.state.type == "player_turn" then
    local commands = battle.queue[1].commands
    local index = battle.state.index
    local command = commands[index]

    if btnp(2) then
      battle.state.index = (index - 2) % #commands + 1
    elseif btnp(3) then
      battle.state.index = index % #commands + 1
    elseif btnp(4) and command.type == "attack" then
      local power = battle.queue[1].strength
      local effect = { type = "damage", power = power }

      battle.state = {
        type = "select_target",
        effects = { effect },
        action_type = "attack",
        targets = find_melee_targets(battle.enemies),
        index = 1
      }
    elseif btnp(4) and command.type == "magic" then
      battle.state = {
        type = "select_spell",
        index = 1
      }
    elseif btnp(4) and command.type == "defend" then
    end
    return
  end

  if battle.state.type == "select_spell" then
    local player = battle.queue[1]
    local spells = player.spells
    local index = battle.state.index
    local spell = spells[index]
    local uses = player.spell_slots[spell.level] or 0

    if btnp(2) then
      battle.state.index = index % #spells + 1
    elseif btnp(3) then
      battle.state.index = (index - 2) % #spells + 1
    elseif btnp(4) and spell.range == "single" and uses > 0 then
      battle.state = {
        type = "select_target",
        effects = spell.effects,
        action_type = "special",
        spell = spell,
        targets = battle.enemies,
        index = 1
      }
    elseif btnp(4) and spell.range == "all" and uses > 0 then
      battle.state = {
        type = "select_all_enemies",
        effects = spell.effects,
        action_type = "special",
        spell = spell
      }
    elseif btnp(4) and spell.range == "ally" and uses > 0 then
      battle.state = {
        type = "select_target",
        effects = spell.effects,
        action_type = "special",
        spell = spell,
        targets = battle.players,
        index = 1
      }
    elseif btnp(5) then
      battle.state = { type = "player_turn", index = 1 }
    end
    return
  end

  if battle.state.type == "select_target" then
    local player = battle.queue[1]
    local index = battle.state.index
    local targets = battle.state.targets
    local target = targets[index]

    if btnp(2) then
      battle.state.index = index % #targets + 1
    elseif btnp(3) then
      battle.state.index = (index - 2) % #targets + 1
    elseif btnp(4) then
      local effects = {}
      for e in all(battle.state.effects) do
        local effect = copy_table(e)
        effect.target = target
        add(effects, effect)
      end

      if battle.state.spell then
        local spell = battle.state.spell
        player.spell_slots[spell.level] -= 1
      end

      player.state = battle.state.action_type
      player.state_started_at = time()

      battle.state = {
        type = "execute_effects",
        effects = effects,
        animation = nil,
        flash = nil,
        message = nil,
        t0 = time(),
        dur = ANIMATION_DUR / 2.0
      }
    elseif btnp(5) and battle.state.spell then
      battle.message = "select spell"
      battle.state = {
        type = "select_spell",
        index = 1
      }
    elseif btnp(5) then
      battle.state = {
        type = "player_turn",
        index = 1
      }
    end
    return
  end

  if battle.state.type == "select_all_enemies" then
    local player = battle.queue[1]

    if btnp(4) then
      local effects = {}
      for target in all(battle.enemies) do
        for e in all(battle.state.effects) do
          local effect = copy_table(e)
          effect.target = target
          add(effects, effect)
        end
      end

      local spell = battle.state.spell
      player.spell_slots[spell.level] -= 1

      player.state = battle.state.action_type
      player.state_started_at = time()

      battle.state = {
        type = "execute_effects",
        effects = effects,
        animation = nil,
        flash = nil,
        message = nil,
        t0 = time(),
        dur = ANIMATION_DUR / 2.0
      }
    elseif btnp(5) then
      battle.message = "select spell"
      battle.state = {
        type = "select_spell",
        index = 1
      }
    end
    return
  end

  if battle.state.type == "execute_effects" and (time() - battle.state.t0) > battle.state.dur then
    battle.message = nil
    battle.state.flash = nil
    battle.state.animation = nil
    battle.state.message = nil

    if #battle.state.effects == 0 then
      battle.state = { type = "end_turn" }
    else
      execute_effect(battle)
    end
    return
  end

  if battle.state.type == "end_turn" then
    local finished = battle.queue[1]
    del(battle.queue, finished)
    add(battle.queue, finished)

    -- collapse columns twice in case both first and second columns are empty
    collapse_column(battle.enemies)
    collapse_column(battle.enemies)

    local next = battle.queue[1]

    if finished.side == "player" then
      finished.state = "idle"
      finished.state_started_at = time()
    end

    if #battle.players == 0 then
      battle.message = "defeat..."
      battle.queue = {}
      battle.state = { type = "lose" }
    elseif #battle.enemies == 0 then
      battle.message = "victory!"
      battle.queue = {}
      battle.state = { type = "win" }
    elseif next.sleep then
      battle.message = next.name .. " is asleep"
      battle.state = {
        type = "execute_effects",
        effects = {},
        t0 = time(),
        dur = MESSAGE_DUR
      }
    elseif next.side == "player" then
      battle.state = { type = "player_turn", index = 1 }
    else
      local effects = next.behavior(next, battle.enemies, battle.players)
      battle.state = {
        type = "execute_effects",
        effects = effects,
        animation = nil,
        flash = nil,
        message = nil,
        t0 = time(),
        dur = 0
      }
    end
  end
end

function find_melee_targets(enemies)
  local targets = {}
  for e in all(enemies) do
    if e.position <= 3 then
      add(targets, e)
    end
  end
  return targets
end

function roll_dice(power)
  local base = power / 2
  local dice = flr(power / 2)
  local roll = 0
  for i = 1, dice do
    roll += flr(rnd(3))
  end
  return flr(base + roll)
end

function collapse_column(enemies)
  local column_1_empty = array_find(enemies, function(e) return e.position <= 3 end) == nil
  if column_1_empty then
    for e in all(enemies) do
      if e.position > 3 then
        e.position -= 3
      end
    end
  end
end

function execute_effect(battle)
  local effects = battle.state.effects
  local effect = effects[1]
  del(effects, effect)

  if effect.type == "damage" then
    local target = effect.target
    local power = effect.power
    local amount = roll_dice(power)

    target.hp = max(target.hp - amount, 0)
    target.sleep = false
    target.sleep_resist = target.sleep_resist_max

    add(effects, { type = "flash", target = target, color = 8 }, 1)
    add(effects, { type = "message", target = target, text = tostring(amount), color = 7 }, 2)

    if target.hp == 0 then
      add(effects, { type = "flash", target = target, color = 1 }, 3)
      add(effects, { type = "kill", target = target }, 4)
    end
    return
  end

  if effect.type == "flash" then
    local target = effect.target
    battle.state.flash = { target = target, color = effect.color }
    battle.state.t0 = time()
    battle.state.dur = FLASH_DUR
    return
  end

  if effect.type == "message" then
    battle.state.message = { target = effect.target, text = effect.text, color = effect.color }
    battle.state.t0 = time()
    battle.state.dur = MESSAGE_DUR
  end

  if effect.type == "banner_message" then
    battle.message = effect.text
    battle.state.t0 = time()
    battle.state.dur = MESSAGE_DUR
  end

  if effect.type == "kill" then
    local target = effect.target
    local success = not target.undead or target.banish or rnd(100) < 66

    if success then
      battle.message = target.name .. " was defeated!"
      battle.state.t0 = time()
      battle.state.dur = MESSAGE_DUR
      del(battle.enemies, target)
      del(battle.players, target)
      del(battle.queue, target)
    else
      target.hp = 1
      add(effects, { type = "message", target = target, text = "undead", color = 7 }, 1)
    end
    return
  end

  if effect.type == "animation" then
    local target = effect.target
    battle.state.animation = { target = target, id = effect.id }
    battle.state.t0 = time()
    battle.state.dur = ANIMATION_DUR
    return
  end

  if effect.type == "sleep" then
    local target = effect.target
    local immune = target.undead

    if immune then
      add(effects, { type = "message", target = target, text = "immune", color = 7 }, 1)
    else
      local roll = roll_dice(effect.power)
      target.sleep_resist = max(0, target.sleep_resist - roll)
      if target.sleep_resist == 0 then
        target.sleep = true
      else
        add(effects, { type = "message", target = target, text = "resist", color = 7 }, 1)
      end
    end

    return
  end

  if effect.type == "banish" then
    local target = effect.target
    local immune = not target.undead

    if immune then
      add(effects, { type = "message", target = target, text = "immune", color = 7 }, 1)
    else
      target.banish = true
      add(effects, { type = "damage", target = target, power = effect.power }, 1)
    end

    return
  end

  if effect.type == "heal" then
    local target = effect.target
    local power = effect.power
    local amount = roll_dice(power)

    target.hp = min(target.hp + amount, target.hp_max)

    add(effects, { type = "flash", target = target, color = 11 }, 1)
    add(effects, { type = "message", target = target, text = tostring(amount), color = 7 }, 2)
    return
  end

  if effect.type == "spawn_enemy" then
    local position_map = {}
    for e in all(battle.enemies) do
      position_map[e.position] = e
    end

    local first_unoccupied = nil
    for pos = 1, 9 do
      if position_map[pos] == nil then
        first_unoccupied = pos
        break
      end
    end

    for position = 1, first_unoccupied - 1 do
      position_map[position].position += 1
    end

    local enemy = spawn_enemy(battle.spawn_dict[effect.enemy_type], 1)
    add(battle.enemies, enemy, 1)
    add(battle.queue, enemy)
    return
  end

  if effect.type == "clear_status" then
    effect.target.sleep = false
    effect.target.sleep_resit = effect.target.sleep_resit_max
  end

  if effect.type == "might" then
    local target = effect.target
    if not target.might then
      target.might = true
      target.strength = flr(target.strength * 1.5)
    end
  end
end

-- #endregion

-- #region drawing
function draw_battle(battle)
  draw_players(battle.players, battle.queue, battle.state)
  draw_enemies(battle.enemies, battle.state)
  draw_player_cards(battle.players, 0, 98)

  if battle.message then
    draw_message(battle.message)
  end

  if battle.state.type == "player_turn" then
    local player = battle.queue[1]
    local index = battle.state.index
    draw_menu(player, 4, 32, index)
  elseif battle.state.type == "select_spell" then
    local player = battle.queue[1]
    local index = battle.state.index
    draw_spell_menu(player, 4, 32, index)
  end
end

function draw_message(message)
  local w, h = 120, 12
  local x, y = 4, 4

  rectfill(x, y, x + w, y + h, 1)
  rect(x, y, x + w, y + h, 7)
  x += 4
  y += 4

  print(message, x, y, 7)
end

function draw_players(players, queue, state)
  local x, y = 106, 32
  local active = queue[1]

  for p in all(players) do
    local x = active == p and x - 8 or x
    draw_combatant(p, x, y, state)
    y += 20
  end
end

function draw_menu(player, x, y, selected_index)
  local w, h = 40, 48
  local pointer_x = x + 4
  local pointer_y = y + 14 + (selected_index - 1) * 8

  rectfill(x, y, x + w, y + h, 1)
  rect(x, y, x + w, y + h, 7)

  local x, y = x + 4, y + 4
  print(player.name, x, y, 7)
  local x, y = x + 8, y + 10
  for cmd in all(player.commands) do
    print(cmd.name, x, y, 7)
    y += 8
  end

  spr(111, pointer_x, pointer_y)
end

function draw_spell_menu(player, x, y, selected_index)
  local w, h = 60, 48
  local pointer_x = x + 4
  local pointer_y = y + 14 + (selected_index - 1) * 8
  local command = player.special.name

  rectfill(x, y, x + w, y + h, 1)
  rect(x, y, x + w, y + h, 7)

  local x, y = x + 4, y + 4
  print(command, x, y, 7)
  local x, y = x + 8, y + 10
  for s in all(player.spells) do
    local uses = player.spell_slots[s.level] or 0
    local color = uses > 0 and 7 or 5
    print(s.name .. " (" .. uses .. ")", x, y, color)
    y += 8
  end

  spr(111, pointer_x, pointer_y)
end

function draw_player_cards(players, x, y)
  local w, h, margin = 22, 16, 8
  local total_w = w * 3 + margin * 2
  x = (128 - total_w) / 2

  for p in all(players) do
    local offset_x = p.hp < 10 and 8 or p.hp < 100 and 4 or 0
    local f = p.hp / p.hp_max

    local color = f == 1 and 7
        or f >= 0.7 and 11
        or f >= 0.4 and 10
        or 8

    rectfill(x, y, x + w, y + h, 1)
    rect(x, y, x + w, y + h, 7)
    print(p.name, x + 3, y + 3, color)
    print(p.hp, x + 9 + offset_x, y + 9, color)
    x += w + margin
  end
end

function draw_enemies(enemies, state)
  local x, y = 64, 72

  for e in all(enemies) do
    local grid_x = flr((e.position - 1) / 3)
    local grid_y = (e.position - 1) % 3
    local x = x - grid_x * 28
    local y = y - grid_y * 20
    draw_combatant(e, x, y, state)
  end
end

function draw_combatant(combatant, x, y, state)
  local selected = state.type == "select_target" and state.targets[state.index] == combatant
      or state.type == "select_all_enemies" and combatant.side == "enemy"

  local tint = state.type == "execute_effects"
      and state.flash
      and state.flash.target == combatant
      and state.flash.color

  local message = state.type == "execute_effects"
      and state.message
      and state.message.target == combatant
      and state.message

  local animation = state.type == "execute_effects"
      and state.animation
      and state.animation.target == combatant
      and state.animation

  if tint then
    for i = 0, 15 do
      pal(i, tint)
    end
  end

  if combatant.side == "player" then
    draw_player(combatant, x, y)
  else
    draw_enemy(combatant, x, y)
  end

  pal()

  if selected then
    spr(111, x - 8, y + 4)
  end

  if combatant.sleep then
    spr(110, x + 16, y)
  end

  if combatant.might then
    spr(126, x + 16, y + 8)
  end

  if message then
    local text = message.text
    local color = message.color
    local progress = min((time() - state.t0) / state.dur, 1.0)
    local x = x + 8 - (#text * 2)
    local y = y + 8 - 10 * progress
    print(text, x, y, color)
  end

  if animation then
    draw_animation(animation.id, x, y, state.t0)
  end
end

function draw_player(player, x, y)
  if player.state == "idle" then
    local sx, sy = id_to_sxsy(player.sprite_id)
    sspr(sx, sy, 16, 16, x, y)
  elseif player.state == "attack" then
    local t = time() - player.state_started_at
    local start_id = player.sprite_id + 2
    local frame = min(flr(t * ANIMATION_FPS), 2) + 1
    local offset = ANIMATION_ATTACK_OFFSETS[frame]
    local id = start_id + offset
    local sx, sy = id_to_sxsy(id)
    local w = frame == 1 and 16 or 20
    local dx = ANIMATION_ATTACK_X_OFFSETS[frame]
    sspr(sx, sy, w, 16, x + dx, y)
  elseif player.state == "special" then
    local start_id = player.sprite_id + 10
    local frame = flr(time() * ANIMATION_FPS) % 2
    local id = start_id + frame * 2
    local sx, sy = id_to_sxsy(id)
    sspr(sx, sy, 16, 16, x, y)
  end
end

function draw_enemy(enemy, x, y)
  local sx, sy = id_to_sxsy(enemy.sprite_id)
  sspr(sx, sy, 16, 16, x, y)
end

function draw_animation(id, x, y, t0)
  local t = time() - (t0 or 0)
  local frame = flr(t * ANIMATION_FPS)
  local id = id + frame * 2
  local sx, sy = id_to_sxsy(id)
  if frame < 3 then
    sspr(sx, sy, 16, 16, x, y)
  end
end

function id_to_sxsy(id)
  local sx = (id % 16) * 8
  local sy = flr(id / 16) * 8
  return sx, sy
end
-- #endregion