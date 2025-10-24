function battle_new(players, enemies)
  local MESSAGE_DUR = 0.75
  local FLASH_DUR = 0.25
  local combatants = {}
  local state = { type = "start", t0 = time(), dur = MESSAGE_DUR }
  local message = "enemies appear!"
  local me = {}

  -- #region player targeting
  function find_melee_targets(enemies)
    local targets = {}

    for enemy in all(enemies) do
      if enemy.position <= 3 then
        add(targets, enemy)
      end
    end

    return targets
  end
  -- #endregion

  function enqueue_effect(effects, new_effect)
    if #effects == 0 then
      add(effects, new_effect)
    else
      add(effects, 1, new_effect)
    end
  end

  function execute_effect(state)
    local effect = state.effects[1]
    del(state.effects, effect)

    if effect.type == "attack" then
      local power = effect.attacker.strength
      local new_effect = { type = "damage", target = effect.target, power = power }

      message = effect.attacker.name .. " attacks"
      state.t0 = time()
      state.dur = MESSAGE_DUR
      enqueue_effect(state.effects, new_effect)
    elseif effect.type == "damage" then
      local damage = compute_damage(effect.power)

      effect.target.hp -= damage
      message = tostring(damage) .. " damage"
      state.t0 = time()
      state.dur = MESSAGE_DUR

      if effect.target.hp <= 0 then
        local new_effect = { type = "kill", target = effect.target }
        enqueue_effect(state.effects, new_effect)
      end
    elseif effect.type == "kill" then
      message = effect.target.name .. " is defeated!"
      state.t0 = time()
      state.dur = MESSAGE_DUR
      del(enemies, effect.target)
      del(players, effect.target)
      del(combatants, effect.target)
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
      local turn = state.type == "player_turn" and state.player == player
      local x = turn and player_x or player_x + 8
      local y = player_y + (player.position - 1) * 10
      spr(player.sprite, x, y)
    end
  end

  local function draw_enemies(enemies)
    local ox, oy = 4, 32
    local w, h = 84, 48
    local enemy_x, enemy_y = ox, oy + 8

    rectfill(ox, oy, ox + w, oy + h, 0)
    rect(ox, oy, ox + w, oy + h, 7)

    for enemy in all(enemies) do
      local selected = state.type == "select_target"
          and state.targets[state.index] == enemy

      local col = combatant_col(enemy)
      local row = combatant_row(enemy)
      local x = enemy_x + col * 24
      local y = enemy_y + (row - 1) * 12
      spr(enemy.sprite, x, y)

      if selected then
        spr(16, x - 8, y + 2)
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

  local function draw_menu(player)
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
        state = { type = "player_turn", player = active }
      elseif done and type == "enemy" then
        del(combatants, active)
        message = active.name .. "'s turn"
        state = { type = "enemy_turn", enemy = active }
      end
      return
    end

    if state.type == "player_turn" then
      if btnp(4) then
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
          effect.target = target
        end

        state = {
          active = state.player,
          type = "exec_effects",
          effects = state.effects,
          animations = {},
          t0 = 0,
          dur = MESSAGE_DUR
        }
      elseif btnp(5) then
        message = state.player.name .. "'s turn"
        state = { type = "player_turn", player = state.player }
      end
      return
    end

    if state.type == "enemy_turn" then
      state = { type = "end_turn", active = state.enemy }
      return
    end

    if state.type == "exec_effects" then
      local time_up = time() - state.t0 > state.dur
      local done = #state.effects == 0 and #state.animations == 0

      if time_up and done then
        state = { type = "end_turn", active = state.active }
      elseif time_up then
        execute_effect(state)
      end
      return
    end

    if state.type == "end_turn" then
      local active = combatants[1]
      local type = active and active.type

      add(combatants, state.active)
      del(combatants, active)

      if type == "player" then
        message = active.name .. "'s turn"
        state = { type = "player_turn", player = active }
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
    draw_enemies(enemies)
    draw_player_stats(players)

    if state.type == "player_turn" then
      draw_menu(state.player)
    end
  end

  return me
end