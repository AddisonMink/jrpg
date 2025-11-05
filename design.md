# Design

## Overview
This is a JRPG in the style of Final Fantasy I, a game that I love, but have a lot of problems with. 

## Dissecting FFI and Forming Design Goals
Here's what's **good** about FFI:
* Attrition-based adventuring. Items are expensive and spells are scarce. Each fight is easy enough, but you have to balance between winning the fight and budgeting resources.
* Party-building. Building a party of 4 from 6 classes makes your game feel unique to you.
* Emphasis on using magic for buffs, debuffs, and crowd-clearing rather than damage. This makes magic have a distinct role from pnysical attacks.
* Magic items. Gaining unlimited access to low-level spells from items that anyone can use is really fun. I'm thinking about the Zeus Gauntlet that let's you cast Bolt2 whenever you want. It diversifies the strategies you can use and increases your sustain without making you strictly stronger.
* Enemy classes. Having categories of enemies with a shared unique mechanic is great! I love the "Harm" class of spells that only damage undead.
* Open exploration. The game opens wide spaces to you and expects you to figure out what to do. It starts gently with just a town and a dungeon, then it's a rim of land around an inland sea, then it's the whole world. This is great progression that makes the player feel like they are discovering things rather than being guided along.
* The story is interesting and weird, but not verbose. You get some pretty interesting lore through 1-line NPC interactions. This lets you imagine a bigger world than what's actually shown.
* The music is top-tier. I have no idea how to replicate that aspect of the game.

Here's what's **bad** about FFI:
* Most enemies are just stat bags that do basic attacks. You often have to prioritize dangerous targets, but that's about as complex as it usually gets.
* Debuffs don't work well. Sleep, Dark, etc. should be game-changers,  but their effects only last 1 round, and if the back mage goes last, they have no effect even when they hit.
* There's one boss strategy: put haste and temper on your attacker and then go to town. Bosses are never interesting and usually die way too fast.
* High defence reduces most physical damage to 1. This makes fighters nearly invulnerable to the point where a team of 4 knights is better for most things than a balanced team.

Here are the design goals for my game:
* Lean into attrition and resource management.
* Have meaningfully different enemies that require different strategies.
* Have a variety of classes with no clear optimal party.
* Have important status effects that both players and enemies use.
* Have a fun, cartoony aesthetic, but not chibi or overly cutesy.
* Have quests that require talking to NPC's and putting things together yourself.
* Have a meaningful difference between dungeons and the overworld. Dungeons should feel dangerous and have more of a ticking clock.

## Battle Design Guidelines
Battles are turn-based and use a circular initiative queue based on a "Speed" stat.

Enemies are arranged in a 3x3 grid. Only the first column can be targeted by basic attacks.

### Overview of player actions.
Every character has "Attack", "Item", and "Wait" commands. Magic-using classes will have a "Magic" command.

* Basic attacks do high single-target damage to the first column of enemies. Good for bosses and bad for crowds.
* Magic attacks can target any enemy, and may target all enemies. Good for sniping high-priority targets or clearing trash mobs.
* Magic spells often inflict some kind of status effect. Putting a crowd of enemies to sleep or blinding a strong attacker is critical for survival.
* Items are used for healing. Special magic items have spell-like effects but may only be used by certain classes. Magic items come in consumable and reusable varieties.
* The "Wait" action just skips your turn.

### Overview of physical attacks.
Physical attacks always hit. The damage formula is `damage(power,armor) = max(flr(power/2 + (power)d3 / 2 - armor), 0)`.

`power = strength + weapon_power`

Armor is a flat value intrinsic to a player or enemy.

### Overview of magic attacks.
Magic attacks always hit. The damage formula is `damage(power) = flr(power/2 + (power)d3 / 2)`.

`power = intelligence + spell_power`

### Overview of status effects.
For every status effect, say "sleep", there is a resistance stat, say "sleep_resist" that functions as a separate "health bar" for that status.

Ailment-inducing effects like the "Sleep" spell reduce the target's "sleep_resist". If that resistance reaches 0, the effect is applied. If the effect is cured, the resistance is reset to maximum.

The formula for the effect of a status-inducing spell is `effect(power) = flr(power/2 + (power)d3 / 2)`.

Example
* Goblin has 5 sleep resist.
* Goblin targeted by sleep effect with power of 6.
* The randomly determined effect is 7.
* Goblin's sleep resist is reduced to 0.
* Goblin falls asleep.
* An effect wakes goblin up, and its sleep resist is reset to 5.

Multiple applications of an effect stack. It may take several sleep spells to put down a big enemy, but it's always possible unless the enemy is completely immune.

The status effects are:
* Sleep - skip your turn. Effect ends when you take damage.
* Blind - physical attacks miss.
* Stun - skip your turn.
* Poison - instant death.
* Silence - can't use magic.

Status effects other than poison end automatically after 2 turns.

### Overview of Enemy Actions
Enemy physical attacks will select a random target, weighted by their position. Players in the first position are much more likely to be targeted.

Enemy magic attacks will select a random target from a uniform distribution.

### Overview of Equipment and Items
Weapons increase the damage of the palyer's basic attacks and may add special properties to their basic attacks, such as status buildup.

Armor determines the player's `armor` status and may increase to their resistances.

Items have an arbitrary effect. Most will be consumable, but some are reusable.

Some weapons can be used like items if they are equipped. For example, a weapon might allow casting Fire if you have it equipped.

## Modes of Play

### Town Mode
The town is essentially a shopping menu where players can buy weapons, armor, and items.

From town, the player can embark on an expedition, which is a journey to a destination. A destination could be a dungeon or another town.

When you enter town, you have to stay at the Inn, which restores HP and spell slots, but costs money. If you have less than the cost of the inn, you spend whatever money you have.

### Expedition Mode
An expedition is a sequence of nodes. Each node gives a chance to use camp items, special items that can only be used in camps.

When moving between nodes, there is a chance of a battle.

Upon reaching an intermediate node, the player can change directions.

When the player enters the last node, the expedition is over and they enter the town or dungeon.

### Battle Mode
A battle plays out. If the players lose, it's game over. If they win, they get some gold. Then they return to the expedition or the dungeon.

### Dungeon Mode
A dungeon is a sequence of nodes. Each node has a chance for an event.

On reaching an intermediate node, the player can change directions.

The last node of a dungeon has a guaranteed event.

The dungeon can be exited from the first node. Then an expedition begins.

## Minimum Shippable Product
There will be a party-select screen. The player will build a team of 3 from 4 classes, with no repeats.

There will be 2 towns A and B, and a 5-node expedition from town A to town B. 

Town A will sell level 1 items, spells, and equipment.

There will be battles between each node, pulled from a random encounter list. If the player dies, they will respawn in town A with half their gold.

Upon reaching town B, there will be a message indicating the end of the demo.

## Equipment and Battle Items
### Level 1 Items
* Tonic - heal status.
* Pill - increase resistance.
* Relic - 1 banish damage to all enemies (thief + priestess only)
* Bomb - fire damage to single target (magician + thief only)
* Dart - put a single target to sleep (huntress + thief only)

## Camp Items
* Coffee - Increase sleep resistance.
* Meat - Restore health.
* Pipe - Restore level 1 spells.

## Status Effects
* Sleep - can't act. Cleared when damaged.
* Might - strength multiplied by 1.5x.
* Invisible - can't be targeted. Cleared when damaged, alone, or asleep.
* Poison - 

## Spells
### Level 1 Spells
* Fire - single-target damage. (Magician)
* Sleep - put all targets to sleep. (Magician, Huntress)
* Banish - damage all undead targets and prevent undead resurrection. (Priestess)
* Heal - restore HP. (Priestess, Huntress)
### Level 2 Spells
* Blind - sets blind status on a single target. (Magician)
* Coma - strong single-target sleep. (Magician, Huntress)
* Silence - prevents spellcasting on a single target. (Priestess)
* Cure - removes negative status effects from all targets. (Priestess, Huntress)


## Monsters
### Level 1 Monsters
* Scamp (Goblin) - basic attacks.
* Hobb (Goblin)- When there are < 3 goblins, summons a new goblin.
* Zombie (Undead) - basic attacks. Undead have a 25% chance to auto-revive unless banished.
* Wolf (Beast) - basic attacks. howls which empowers and wakes up other wolves.
* Witch (Magician) - randomly casts sleep and fire.
### Level 2 Monsters
* Lizard (Dragon) - poison attacks.
* Ghost (Undead, Magician) - starts invisible. casts and summons zombie
* Wolfman (Beast) - heals attacking.
* 