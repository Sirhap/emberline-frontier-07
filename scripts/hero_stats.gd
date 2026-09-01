class_name HeroStats
extends RefCounted

## Read-only combat snapshot. Multipliers default to 100%; catalogs fill later.

var max_health: int = 120
## 100 = 100%
var attack_power: int = 100
var defense: int = 2
var armor_capacity: int = 2
var move_speed: float = 165.0
## 1.0 default
var dash_cooldown_mult: float = 1.0
## seconds
var dash_invuln_bonus: float = 0.0
## 1.0 default
var all_damage_mult: float = 1.0
var melee_damage_mult: float = 1.0
var ranged_cooldown_mult: float = 1.0
var clone_damage_mult: float = 1.0
var clone_skill_cooldown_mult: float = 1.0
var clone_duration_bonus: float = 0.0
## extra clones beyond skill rank; default 0
var clone_count_bonus: int = 0
var wave_heal_ratio: float = 0.0
var scrap_reward_mult: float = 1.0
var knight_counterfire: bool = false
var knight_overdrive_stacks: int = 0
## not derived here, just stored if useful
var skill_rank: int = 0


## Builds a snapshot with safe defaults (100% multipliers, knight-ish zeros).
static func defaults() -> HeroStats:
	return HeroStats.new()
