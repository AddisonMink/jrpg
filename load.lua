ASSET_MAP = {
  warrior = 0,
  elf = 32,
  wizard = 64,
  priestess = 96,
  thief = 128,
  goblin = 192,
  zombie = 224
}

function sprite_id_to_address(id)
  local row = flr(id / 16)
  local col = id % 16
  return row * 512 + col * 4
end

function cache_sprite_data(src_id, dest_id, size_x, size_y)
  local size_x = size_x or 8
  local size_y = size_y or size_x
  local size = size or 8
  local bytes = flr(size_x / 2)
  local src_addr0 = sprite_id_to_address(src_id) + 0x8000
  local dest_addr0 = sprite_id_to_address(dest_id)

  for y = 0, size_y - 1 do
    local src_addr = src_addr0 + y * 64
    local dest_addr = dest_addr0 + y * 64
    memcpy(dest_addr, src_addr, bytes)
  end
end

function cache_player_sprite_data(name, dest_id)
  local src_id = ASSET_MAP[name]
  cache_sprite_data(src_id, dest_id, 128, 16)
end

function cache_enemy_sprite_data(name, dest_id)
  local src_id = ASSET_MAP[name]
  cache_sprite_data(src_id, dest_id, 16, 16)
end