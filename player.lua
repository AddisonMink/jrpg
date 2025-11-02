function warrior_new(name)
  return {
    type = "warrior",
    name = name,
    special = nil,
    strength = 1,
    hp_max = 10
  }
end

function elf_new(name)
  return {
    type = "elf",
    name = name,
    special = { name = "elf", type = "magic" },
    strength = 0,
    hp_max = 8,
    spell_slots = { 1 },
    spells = { SPELL_SLEEP, SPELL_HEAL }
  }
end

function wizard_new(name)
  return {
    type = "wizard",
    name = name,
    special = { name = "spell", type = "magic" },
    strength = 0,
    hp_max = 6,
    spell_slots = { 2 },
    spells = { SPELL_FIRE, SPELL_SLEEP }
  }
end

function priestess_new(name)
  return {
    type = "priestess",
    name = name,
    special = { name = "pray", type = "magic" },
    strength = -1,
    hp_max = 6,
    spell_slots = { 2 },
    spells = { SPELL_HEAL, SPELL_BANISH }
  }
end