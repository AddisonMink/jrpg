function load_select_team()
  cache_enemy_sprite_data("warrior", 2)
  cache_enemy_sprite_data("elf", 4)
  cache_enemy_sprite_data("wizard", 6)
  cache_enemy_sprite_data("priestess", 8)

  return {
    classes = { "warrior", "elf", "wizard", "priestess" },
    names = { "vlad", "luna", "merl", "hild" },
    descriptions = {
      "a burly fighter",
      "a magic swordswoman",
      "an old enchanter",
      "a young shrine maiden"
    },
    selected = {},
    index = 1,
    state = "select"
  }
end

function update_select_team(select_team)
  if select_team.state == "select" then
    if btnp(2) then
      select_team.index = (select_team.index - 2) % #select_team.classes + 1
    elseif btnp(3) then
      select_team.index = select_team.index % #select_team.classes + 1
    elseif btnp(4) then
      local class = select_team.classes[select_team.index]
      add(select_team.selected, { class = class, index = select_team.index })
    elseif btnp(5) then
      del(select_team.selected, select_team.selected[#select_team.selected])
    end

    if #select_team.selected >= 3 then
      select_team.state = "confirm"
    end
    return
  end

  if select_team.state == "confirm" then
    if btnp(4) then
      local result = {}
      for s in all(select_team.selected) do
        add(result, s.class)
      end
      return result
    elseif btnp(5) then
      select_team.state = "select"
      select_team.selected = {}
    end
    return
  end
end

function draw_select_team(select_team)
  local prompt = "select team (pick 3)"
  local y = 8
  local pointer_y = 40 + (select_team.index - 1) * 20 + 4

  print(prompt, 64 - (#prompt * 4) / 2, y, 7)
  y += 16

  print("selected:", 8, y, 7)
  local x = #"selected:" * 4 + 8 + 4
  for s in all(select_team.selected) do
    sspr(s.index * 16, 0, 16, 16, x, y - 8)
    x += 20
  end
  y += 16

  for i = 1, #select_team.classes do
    local class = select_team.classes[i]
    local name = select_team.names[i]
    local description = select_team.descriptions[i]
    local x = 16

    sspr(i * 16, 0, 16, 16, x, y - 3)
    x += 20
    print(class, x, y, 7)
    print(description, x, y + 8, 6)
    y += 20
  end

  spr(111, 8, pointer_y)

  if select_team.state == "confirm" then
    local w, h = 64, 32
    local x, y = 64 - w / 2, 64
    local confirm_prompt = "use this team?"
    local prompt_x = (w - #confirm_prompt * 4) / 2
    local prompt_y = (h - 8) / 2

    rectfill(x, y, x + w, y + h, 0)
    rect(x, y, x + w, y + h, 7)
    print(confirm_prompt, x + prompt_x, y + prompt_y, 7)
  end
end