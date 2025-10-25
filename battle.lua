function battle_new(players, enemies)
  -- #region constants
  local MESSAGE_DUR = 0.5
  local FLASH_DUR = 0.5

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
  -- #endregion

  local combatants = {}
  local state = { type = "start", t0 = time(), dur = MESSAGE_DUR }
  local message = "enemies appear!"
  local me = {}

  local function find_melee_targets(enemies)
    local targets = {}

    for enemy in all(enemies) do
      if enemy.position <= 3 then
        add(targets, enemy)
      end
    end

    return targets
  end

  local function find_single_targets(enemies)
    return enemies
  end

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

  local function compute_damage(power)
    local roll = flr(rnd(4)) + 1
    return max(1, power + roll)
  end

  local function execute_effect(state)
    local effect = state.effects[1]
    del(state.effects, effect)

    if effect.type == "attack" then
      local power = effect.attacker.strength
      local new_effect = { type = "damage", target = effect.target, power = power }

      message = effect.attacker.name .. " attacks"
      state.t0 = time()
      state.dur = MESSAGE_DUR
      add(state.effects, new_effect, 1)
    elseif effect.type == "damage" then
      local damage = compute_damage(effect.power)

      effect.target.hp -= damage
      message = tostring(damage) .. " damage"
      state.t0 = time()
      state.dur = 0

      local new_effect = { type = "flash", target = effect.target, color = 8 }
      add(state.effects, new_effect, 1)

      if effect.target.hp <= 0 then
        local new_effect = { type = "kill", target = effect.target }
        add(state.effects, new_effect, 2)
      end
    elseif effect.type == "kill" then
      message = effect.target.name .. " is defeated!"
      state.t0 = time()
      state.dur = MESSAGE_DUR
      del(enemies, effect.target)
      del(players, effect.target)
      del(combatants, effect.target)
    elseif effect.type == "flash" then
      state.t0 = time()
      state.dur = FLASH_DUR
      state.animation = { type = "flash", target = effect.target, color = effect.color }
    elseif effect.type == "use_spell" then
      local valid = effect.target.spell_uses
          and effect.target.spell_uses[effect.level]

      if valid then
        local uses = effect.target.spell_uses[effect.level]
        effect.target.spell_uses[effect.level] = max(0, uses - 1)
        message = effect.target.name .. " casts " .. effect.name
        state.t0 = time()
        state.dur = MESSAGE_DUR
      end
    elseif effect.type == "overlay" then
      state.t0 = time()
      state.animation = { type = "overlay", target = effect.target, animation = effect.animation }
      state.dur = effect.animation.dur
    end
  end

  local function collapse_column(enemies, col)
    local first_col_empty = true
    for enemy in all(enemies) do
      if enemy.position <= 3 then
        first_col_empty = false
        break
      end
    end

    if first_col_empty then
      for enemy in all(enemies) do
        if enemy.position > 3 then
          enemy.position -= 3
        end
      end
    end
  end

  -- #region draw functions
  local function draw_message(text)
    local ox, oy = 4, 18
    local w, h = 118, 12

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)
    print(text, ox + 4, oy + 4, 7)
  end

  local function draw_players(players)
    local ox, oy = 90, 32
    local w, h = 32, 48
    local player_x, player_y = ox + 6, oy + 6

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)

    for player in all(players) do
      local turn = (state.type == "player_turn" or state.type == "select_menu_option")
          and state.player == player

      local x = turn and player_x or player_x + 8
      local y = player_y + (player.position - 1) * 10

      local anim = state.animation
          and state.animation.target == player
          and state.animation

      local tint = anim
          and anim.type == "flash"
          and anim.color

      if tint then
        for i = 0, 15 do
          pal(i, tint)
        end
      end
      spr(player.sprite, x, y)
      pal()
    end
  end

  local function draw_enemies(enemies, state)
    local ox, oy = 4, 32
    local w, h = 84, 48
    local enemy_x, enemy_y = ox, oy + 8

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)

    for enemy in all(enemies) do
      local anim = state.animation
          and state.animation.target == enemy
          and state.animation

      local tint = anim
          and anim.type == "flash"
          and anim.color

      local overlay = anim
          and anim.type == "overlay"
          and anim.animation

      local selected = state.type == "select_target"
          and state.targets[state.index] == enemy

      local row = (9 - enemy.position) % 3 + 1
      local col = flr((9 - enemy.position) / 3) + 1
      local x = enemy_x + col * 24
      local y = enemy_y + (row - 1) * 12

      if tint then
        for i = 0, 15 do
          pal(i, tint)
        end
      end
      spr(enemy.sprite, x, y)
      pal()

      if selected then
        spr(16, x - 8, y + 2)
      end

      if overlay then
        local frame_count = #overlay.frames
        local frame_index = flr((time() - state.t0) * overlay.fps) % frame_count + 1
        local frame = overlay.frames[frame_index]
        spr(frame, x, y)
      end
    end
  end

  local function draw_player_stats(players)
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

  local function draw_menu(player, index)
    local ox, oy = 8, 36
    local w, h = 60, 40
    local x, y = ox + 4, oy + 4
    local pointer_y = y + 10 + (index - 1) * 8

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)

    print(player.name, x, y, 7)
    y += 10
    print("attack", x + 8, y, 7)
    y += 8
    print(player.command.name, x + 8, y, 7)
    y += 8
    print("item", x + 8, y, 5)

    spr(16, x, pointer_y)
  end

  local function draw_spell_menu(state)
    local ox, oy = 8, 36
    local w, h = 60, 40
    local x, y = ox + 4, oy + 4
    local pointer_y = y + 10 + (state.index - 1) * 8

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)

    print(state.name, x, y, 7)
    y += 10
    for spell in all(state.spells) do
      local name = spell.name
      local level = spell.level
      local uses = state.player.spell_uses[level] or 0
      local color = uses > 0 and 7 or 5
      print(name .. " (" .. uses .. ")", x + 8, y, color)
      y += 8
    end

    spr(16, x, pointer_y)
  end
  -- #endregion

  -- #region initialization
  -- initialize combatants
  for p in all(players) do
    add(combatants, p)
  end

  for e in all(enemies) do
    add(combatants, e)
  end
  -- #endregion

  function me:update()
    if state.type == "start" then
      local active = combatants[1]
      local type = active.type
      local done = time() - state.t0 > state.dur

      if done and type == "player" then
        del(combatants, active)
        message = active.name .. "'s turn"
        state = { type = "player_turn", player = active, index = 1 }
      elseif done and type == "enemy" then
        del(combatants, active)
        message = active.name .. "'s turn"
        state = { type = "enemy_turn", enemy = active }
      end
      return
    end

    if state.type == "player_turn" then
      if btnp(3) then
        state.index = (state.index % 3) + 1
      elseif btnp(2) then
        state.index = (state.index - 2) % 3 + 1
      elseif btnp(4) and state.index == 1 then
        local effect = { type = "attack", attacker = state.player, target = nil }
        local effects = { effect }
        local targets = find_melee_targets(enemies)

        message = "select target"

        state = {
          type = "select_target",
          player = state.player,
          effects = effects,
          targets = targets,
          index = 1
        }
      elseif btnp(4) and state.index == 2 then
        local type = state.player.command.type
        if type == "command" then
          message = "command not implemented"
        elseif type == "spell" then
          state = {
            type = "select_menu_option",
            player = state.player,
            name = state.player.command.name,
            spells = state.player.command.spells,
            index = 1
          }
        end
      end
      return
    end

    if state.type == "select_menu_option" then
      if btnp(3) then
        state.index = (state.index % #state.spells) + 1
      elseif btnp(2) then
        state.index = (state.index - 2) % #state.spells + 1
      elseif btnp(4) then
        local spell = state.spells[state.index]
        local uses = state.player.spell_uses[spell.level] or 0
        if uses > 0 then
          local effects = spell.effects(state.player)

          local targets = spell.range == "melee" and find_melee_targets(enemies)
              or spell.range == "single" and find_single_targets(enemies)

          message = "select target"
          state = {
            type = "select_target",
            player = state.player,
            effects = effects,
            targets = targets,
            index = 1
          }
        end
      elseif btnp(5) then
        message = state.player.name .. "'s turn"
        state = { type = "player_turn", player = state.player, index = 1 }
      end
      return
    end

    if state.type == "select_target" then
      if btnp(2) then
        state.index = (state.index % #state.targets) + 1
      elseif btnp(3) then
        state.index = (state.index - 2) % #state.targets + 1
      elseif btnp(4) then
        local target = state.targets[state.index]

        for effect in all(state.effects) do
          if not effect.target then
            effect.target = target
          end
        end

        state = {
          active = state.player,
          type = "exec_effects",
          effects = state.effects,
          t0 = 0,
          dur = MESSAGE_DUR
        }
      elseif btnp(5) then
        message = state.player.name .. "'s turn"
        state = { type = "player_turn", player = state.player, index = 1 }
      end
      return
    end

    if state.type == "enemy_turn" then
      local target = enemy_find_target(players, "melee")
      local effect1 = { type = "flash", target = state.enemy, color = 7 }
      local effect2 = { type = "attack", attacker = state.enemy, target = target }
      local effects = { effect1, effect2 }

      state = {
        active = state.enemy,
        type = "exec_effects",
        effects = effects,
        t0 = 0,
        dur = MESSAGE_DUR
      }
      return
    end

    if state.type == "exec_effects" then
      local time_up = time() - state.t0 > state.dur
      local done = #state.effects == 0

      if time_up and done then
        state = { type = "end_turn", active = state.active }
      elseif time_up then
        state.animation = nil
        execute_effect(state)
      end
      return
    end

    if state.type == "end_turn" then
      local active = combatants[1]
      local type = active and active.type

      add(combatants, state.active)
      del(combatants, active)
      collapse_column(enemies, 1)

      if #players == 0 then
        message = "defeated..."
        state = { type = "lose" }
      elseif #enemies == 0 then
        message = "victory!"
        state = { type = "win" }
      elseif type == "player" then
        message = active.name .. "'s turn"
        state = { type = "player_turn", player = active, index = 1 }
      elseif type == "enemy" then
        message = active.name .. "'s turn"
        state = { type = "enemy_turn", enemy = active }
      end
      return
    end
  end

  function me:draw()
    draw_message(message)
    draw_players(players)
    draw_enemies(enemies, state)
    draw_player_stats(players)

    if state.type == "player_turn" then
      draw_menu(state.player, state.index)
    elseif state.type == "select_menu_option" then
      draw_spell_menu(state)
    end
  end

  return me
end