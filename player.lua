function warrior_new(name)
  return {
    type = "warrior",
    name = name,
    special = nil,
    hp_max = 100,
    strength = 10
  }
end

function elf_new(name)
  return {
    type = "elf",
    name = name,
    special = { name = "elf", type = "magic" },
    hp_max = 80,
    strength = 6,
    spell_slots = { 1 },
    spells = { SPELL_SLEEP, SPELL_HEAL }
  }
end

function wizard_new(name)
  return {
    type = "wizard",
    name = name,
    special = { name = "spell", type = "magic" },
    hp_max = 60,
    strength = 4,
    spell_slots = { 2 },
    spells = { SPELL_FIRE, SPELL_SLEEP }
  }
end

function priestess_new(name)
  return {
    type = "priestess",
    name = name,
    special = { name = "pray", type = "magic" },
    hp_max = 60,
    strength = 4,
    spell_slots = { 2 },
    spells = { SPELL_HEAL, SPELL_BANISH }
  }
end