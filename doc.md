# Memory Layout

## Sprites
| Content | Sprite ID | Size |
|-|-|-|
| Player 1 Spritesheet | ID 0 | 128x16 px | Loaded from data |
| Player 2 Spritesheet | ID 32 | 128x16 px | Loaded from data |
| Player 3 Spritesheet | ID 64 | 128x16 px | Loaded from data |
| Enemy 1 Sprite | ID 96 | 16x16 px | Loaded from data |
| Enemy 2 Sprite | ID 98 | 16x16 px | Loaded from data |
| Enemy 3 Sprite | ID 100 | 16x16 px | Loaded from data |
| Enemy 4 Sprite | ID 102 | 16x16 px | Loaded from data |
| Sleep Animation | ID 104 | 48x16 px | On disk |
| Sleep Icon | ID 110 | 8x8 px | On disk |
| Pointer Icon | ID 111 | 8x8 px | On disk |
| ? Icon | ID 126 | 8x8 px | On disk |
| ? Icon | ID 127 | 8x8 px | On disk |
| Flame Animation | ID 128 | 48x16 px | On disk |


animation = {
  fps = int?
  loop = bool?
  frames = {
    {sx,sy,w,h,ox?,oy?}
  }
}

combatant = {
  type = "player" | "enemy",
  name = string,
  animation = animation
  hp = int,
  hp_max = int,
  speed = int,
  spell_slots = [int],
  spells = map[int,[spell]],  
  sleep_resist = int,
  sleep = bool,  
  undead = bool,
  -- enemy-only fields
  behavior = (me,enemies,players) => [effect],
  -- player-only fields
  strength = int,
  command = string,
}

spell = {
  name = string,
  level = int,
  range = "melee" | "single" | "enemies" | "ally",
  effects = [effect]
}

effect
  = damage { target, power, type }
  | flash { target, color }
  | message { text }


  | overlay_message { target, text, color }
  | set_message { text }
  | set_sleep { target }
  | wake_up { target }
  | overlay_animation { target, animation }
  | kill { target }

global_state = {
  players = [combatants],
  enemies = [combatants],
  queue = [combatants],
  message = string
}

state
  = selecting_action { index = int }
  | selecting_spell { index = int }
  | selecting_single_target { effects = [effect], targets = [enemy], index = int }
  | selecting_all_enemies { effects = [effect] }
  | enemy_turn 
  | executing_effects { 
    effects = [effect],
    t0 = time,
    dur = time
    overlay_animation = { target = combatant, animation = animation },
    overlay_message = { target = combatant, message = string, color = int },
    flash = { target = combatant, color = int },
  }
  | ending_turn
  | win
  | lose