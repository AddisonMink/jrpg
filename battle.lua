function battle_new(players, enemies)
  local MESSAGE_DUR = 0.5
  local FLASH_DUR = 0.25
  local OVERLAY_MESSAGE_DUR = 0.5

  -- #region initialization
  local message = "an enemy appears!"
  local queue = {}
  local state = { type = "start", t0 = time(), dur = 1.0 }
  local me = {}

  for player in all(players) do
    add(queue, player)
  end

  for enemy in all(enemies) do
    add(queue, enemy)
  end
  -- #endregion

  -- #region draw functions
  local function combatant_draw(combatant, x, y)
    local animation = combatant.animation.animation
    local t0 = combatant.animation.t0

    local single_selected = state.type == "select_target"
        and state.targets[state.index] == combatant

    local tint = state.flash
        and state.flash.target == combatant
        and state.flash.color

    local message = state.overlay_message
        and state.overlay_message.target == combatant
        and state.overlay_message

    if tint then
      for i = 0, 15 do
        pal(i, tint)
      end
    end
    animation_draw(animation, x, y, t0)
    pal()

    if single_selected then
      spr(16, x - 8, y + 2)
    end

    if message then
      local text = message.text
      local color = message.color
      local progress = min(1, (time() - state.t0) / OVERLAY_MESSAGE_DUR)
      local x = x - flr(#text * 4 / 2) + 8
      local y = y + 4 - flr(progress * 8)
      print(text, x, y, color)
    end
  end

  local function draw_players(players, x, y)
    local w, h = 32, 80
    rectfill(x, y, x + w - 1, y + h - 1, 0)
    rect(x, y, x + w - 1, y + h - 1, 7)

    for i = #players, 1, -1 do
      local player = players[i]
      local x = x + w - 20
      local y = y + i * (h / #players) - (h / #players - 16) / 2 - 16
      combatant_draw(player, x, y)
    end
  end

  local function draw_player_stat_block(player, x, y)
    local w, h = 32, 20
    rectfill(x, y, x + w - 1, y + h - 1, 0)
    rect(x, y, x + w - 1, y + h - 1, 7)
    print(player.name, x + 4, y + 4, 7)
    print("hp " .. player.hp.current, x + 4, y + 12, 7)
  end

  local function draw_player_stat_blocks(players, x, y)
    local w = 126
    for i = 1, #players, 1 do
      local player = players[i]
      local px = x + (i - 1) * (w / #players)
      draw_player_stat_block(player, px, y)
    end
  end

  local function draw_enemies(enemies, x, y)
    local w, h = 80, 80
    rectfill(x, y, x + w - 1, y + h - 1, 0)
    rect(x, y, x + w - 1, y + h - 1, 7)

    for i = 9, 1, -1 do
      local enemy = array_find(enemies, function(e) return e.position == i end)
      if enemy then
        local i = 9 - i + 1
        local ey = y + (i - 1) % 3 * (w / 3) + (w / 3 - 16) / 2
        local ex = x + flr((i - 1) / 3) * (h / 3) + (h / 3 - 16) / 2
        combatant_draw(enemy, ex, ey)
      end
    end
  end

  local function draw_message(message, x, y)
    local w, h = 116, 14
    rectfill(x, y, x + w - 1, y + h - 1, 0)
    rect(x, y, x + w - 1, y + h - 1, 7)
    print(message, x + 4, y + 4, 7)
  end

  local function draw_menu(player, x, y, index)
    local w, h = 48, 48
    local pointer_y = y + 14 + (index - 1) * 8

    rectfill(x, y, x + w - 1, y + h - 1, 0)
    rect(x, y, x + w - 1, y + h - 1, 7)

    x += 4
    y += 4
    print(player.name, x, y, 7)
    y += 10

    print("attack", x + 10, y, 7)
    y += 8
    print("command", x + 10, y, 5)
    y += 8
    print("item", x + 10, y, 5)
    y += 8
    print("wait", x + 10, y, 7)
    y += 8
    spr(16, x, pointer_y)
  end
  -- #endregion

  -- #region targeting functions
  function find_melee_targets()
    local targets = {}
    for enemy in all(enemies) do
      if enemy.position <= 3 then
        add(targets, enemy)
      end
    end
    return targets
  end
  -- #endregion

  -- #region effect execution functions
  local function roll(power)
    return flr(rnd(4)) + 1 + power
  end

  local function collapse_columns()
    local front_column_empty = array_find(enemies, function(e) return e.position <= 3 end) == nil
    if front_column_empty then
      for enemy in all(enemies) do
        enemy.position -= 3
      end
    end
  end

  local function execute_effect()
    local effect = state.effects[1]
    del(state.effects, effect)

    if effect.type == "damage" then
      local target = effect.target
      local damage = roll(effect.power)
      local message = damage .. " damage"

      target.hp.current = max(0, target.hp.current - damage)

      add(state.effects, { type = "flash", target = target, color = 8 }, 1)
      add(state.effects, { type = "overlay_message", target = target, text = tostring(damage), color = 7 })

      if target.hp.current <= 0 then
        add(state.effects, { type = "kill", target = target }, 3)
      end
      return
    end

    if effect.type == "flash" then
      local target = effect.target
      state.flash = { target = target, color = effect.color }
      state.t0 = time()
      state.dur = FLASH_DUR
      return
    end

    if effect.type == "message" then
      message = effect.text
      state.t0 = time()
      state.dur = MESSAGE_DUR
      return
    end

    if effect.type == "overlay_message" then
      state.overlay_message = { target = effect.target, text = effect.text, color = effect.color }
      state.t0 = time()
      state.dur = OVERLAY_MESSAGE_DUR
      return
    end

    if effect.type == "kill" then
      del(queue, effect.target)
      del(enemies, effect.target)
      del(players, effect.target)
      add(state.effects, { type = "message", text = effect.target.name .. " was defeated!" })
      return
    end
  end

  -- #endregion

  function me:update()
    if state.type == "start" then
      if time() - state.t0 > state.dur then
        message = queue[1].name .. "'s turn"
        state = { type = "select_action", index = 1 }
      end
      return
    end

    if state.type == "select_action" then
      local active = queue[1]
      if btnp(2) then
        state.index = (state.index - 2) % 4 + 1
      elseif btnp(3) then
        state.index = state.index % 4 + 1
      elseif btnp(4) and state.index == 1 then
        message = "select target"
        targets = find_melee_targets()
        state = { type = "select_target", targets = targets, index = 1 }
      end
      return
    end

    if state.type == "select_target" then
      if btnp(2) then
        state.index = state.index % #state.targets + 1
      elseif btnp(3) then
        state.index = (state.index - 2) % #state.targets + 1
      elseif btnp(4) then
        local player = queue[1]
        local anim = player.animations.attack
        local target = state.targets[state.index]
        local power = player.strength
        local effect = { type = "damage", target = target, power = power }

        player.animation = {
          animation = player.animations.attack,
          t0 = time()
        }

        state = {
          type = "execute_effects",
          effects = { effect },
          t0 = time(),
          dur = 0,
          overlay_animation = nil,
          overlay_message = nil,
          flash = nil
        }
      end
      return
    end

    if state.type == "execute_effects" then
      if time() - state.t0 > state.dur then
        message = ""
        state.overlay_animation = nil
        state.overlay_message = nil
        state.flash = nil

        if #state.effects == 0 then
          state = { type = "end_turn" }
        else
          execute_effect()
        end
      end
      return
    end

    if state.type == "end_turn" then
      local active = queue[1]
      local win = #enemies == 0
      local lose = #players == 0

      del(queue, active)
      add(queue, active)
      collapse_columns()

      if active.type == "player" then
        active.animation = { animation = active.animations.idle, t0 = time() }
      end

      if #players == 0 then
        message = "the party was defeated..."
        state = { type = "lose" }
      elseif #enemies == 0 then
        message = "enemies defeated!"
        state = { type = "win" }
      elseif queue[1].type == "player" then
        message = queue[1].name .. "'s turn"
        state = { type = "select_action", index = 1 }
      elseif queue[1].type == "enemy" then
        local enemy = queue[1]
        local effects = enemy.behavior(enemy, enemies, players)
        state = {
          type = "execute_effects",
          effects = effects,
          t0 = time(),
          dur = 0,
          overlay_animation = nil,
          overlay_message = nil,
          flash = nil
        }
      end
      return
    end
  end

  function me:draw()
    draw_message(message, 6, 4)
    draw_enemies(enemies, 6, 21)
    draw_players(players, 90, 21)
    draw_player_stat_blocks(players, 6, 104)

    if state.type == "select_action" then
      local active = queue[1]
      draw_menu(active, 10, 25, state.index)
    end
  end

  return me
end