pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function warrior_new(name, position)
  local hp = 10

  return {
    type = "player",
    name = name,
    sprite = 1,
    position = position,
    hp_max = hp,
    hp = hp
  }
end

function goblin_new(position)
  local hp = 3

  return {
    type = "enemy",
    name = "goblin",
    sprite = 2,
    position = position,
    hp_max = hp,
    hp = hp
  }
end

player1 = warrior_new("bart", 1)
player2 = warrior_new("vlad", 2)
player3 = warrior_new("lena", 3)
player4 = warrior_new("zara", 4)
enemy1 = goblin_new(1)
enemy2 = goblin_new(2)
enemy3 = goblin_new(3)
enemy4 = goblin_new(4)

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
  enemy4
}

combatants = {}

function _init()
  for player in all(players) do
    add(combatants, player)
  end

  for enemy in all(enemies) do
    add(combatants, enemy)
  end

  active = combatants[1]
end

function _update()
  message = active.name .. "'s turn"
end

function _draw()
  cls(2)
  draw_message(message)
  draw_players(players)
  draw_enemies(enemies)
  draw_player_stats(players)

  if active.type == "player" then
    draw_menu(active)
  end
end

function draw_message(text)
  local ox, oy = 4, 18
  local w, h = 120, 12

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
  local enemy_x, enemy_y = ox + 16, oy + 8

  rectfill(ox, oy, ox + w, oy + h, 0)
  rect(ox, oy, ox + w, oy + h, 7)

  for enemy in all(enemies) do
    local pos = 9 - enemy.position
    local x = enemy_x + flr(pos / 3) * 24
    local y = enemy_y + (pos % 3) * 12
    spr(enemy.sprite, x, y)
  end
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
  print("attack", x + 8, y, 7)
  y += 8
  print("command", x + 8, y, 7)
  y += 8
  print("item", x + 8, y, 7)
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
