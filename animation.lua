ANIMATION_WARRIOR_IDLE = {
  frames = {
    { 0, 32, 16, 16 }
  }
}

ANIMATION_WARRIOR_ATTACK = {
  loop = false,
  fps = 12,
  frames = {
    { 16, 32, 16, 16, -3 },
    { 32, 32, 20, 16, -5 - 6 },
    { 56, 32, 20, 16, -5 - 6 }
  }
}

ANIMATION_WARRIOR_ITEM = {
  frames = {
    { 80, 32, 16, 16 }
  }
}

ANIMATION_WIZARD_IDLE = {
  frames = {
    { 32, 48, 16, 16 }
  }
}

ANIMATION_WIZARD_ATTACK = {
  loop = false,
  fps = 12,
  frames = {
    { 48, 48, 16, 16, -2 },
    { 64, 48, 16, 16, -4 - 4 },
    { 80, 48, 16, 16, -4 - 4 }
  }
}

ANIMATION_WIZARD_ITEM = {
  fps = 8,
  frames = {
    { 48, 48, 16, 16 },
    { 96, 48, 16, 16 }
  }
}

ANIMATION_ELF_IDLE = {
  frames = {
    { 16, 0, 16, 16 }
  }
}

function enemy_animation(sx, sy, sw, sh)
  local anim = {
    frames = {
      { sx, sy, sw, sh }
    }
  }
  return { animation = anim, t0 = time() }
end

function animation_draw(animation, x, y, t0)
  local t0 = t0 or 0
  local fps = animation.fps or 1
  local loop = animation.loop ~= false
  local n = #animation.frames
  local i = flr((time() - t0) * fps) + 1

  local frame_index = loop and (i - 1) % n + 1
      or min(i, n)

  local frame = animation.frames[frame_index]
  local ox = frame[5] or 0
  local oy = frame[6] or 0
  sspr(frame[1], frame[2], frame[3], frame[4], x + ox, y + oy)
end