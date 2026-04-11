# Agentic AI Game Systems Report

## 1. Purpose

This report converts the original planning notes into a structured implementation brief for Agentic AI and human collaborators.

The goal is to guide development of a high-quality Godot game architecture that is:

- Dynamic: configurable through Inspector and Resource data
- Scene-driven: level and system composition is arranged directly in scenes
- Data-driven: content and behavior can be changed without repeatedly editing core code
- Extensible: new content and systems can be added without breaking the foundation
- Suitable for advanced game development: avoids fragile hardcoded dependencies and supports scalable iteration

This document is intended to help AI agents:

- understand the design philosophy
- implement systems in the correct order
- avoid coupling gameplay logic too tightly to UI or scene paths
- produce reusable, maintainable, high-level game systems

---

## 2. Core Design Philosophy

The project should be structured around the following principle:

`Scenes arrange experience. Resources define content. Scripts execute behavior.`

This means:

- Scene authors place Nodes manually in Godot for layout, interaction, and composition
- Resource files define gameplay data such as perks, relics, enemies, events, and waves
- Scripts process those definitions at runtime and coordinate systems through clean APIs and signals

The intended outcome is a game that can evolve rapidly through content iteration rather than repeated rewrites of hardcoded logic.

---

## 3. Architectural Layers

The project should be divided into 4 main layers.

### 3.1 Scene Layer

Responsible for scene composition and manual authoring in the Godot editor.

Examples:

- combat arenas
- exploration rooms
- spawn points
- reward screens
- event triggers
- shop areas
- enemy placements
- UI anchors

Design rule:

- Systems should support manual scene layout by the designer
- Scripts should avoid assuming rigid scene tree paths whenever possible

### 3.2 Component Layer

Responsible for behavior attached to gameplay objects.

Examples:

- player movement
- active skill component
- reward UI component
- event room interaction
- enemy brain
- hurtbox/health component

Design rule:

- Components should have clear single responsibilities
- Avoid turning large scripts like `player.gd` into a catch-all logic file

### 3.3 Manager Layer

Responsible for shared runtime orchestration and cross-system coordination.

Examples:

- `RunManager`
- `EncounterManager`
- `StatCalculator`
- existing global state managers

Design rule:

- Shared runtime state should be centralized
- Managers should expose APIs and signals rather than requiring direct scene coupling

### 3.4 Data Layer

Responsible for game content definitions using `Resource` files.

Examples:

- perks
- relics
- events
- wave sets
- enemy definitions
- skill definitions

Design rule:

- New content should be created by adding `.tres` resources and optional new scenes
- Core systems should read content data rather than hardcode it

---

## 4. Global Engineering Rules

All new systems should follow these rules.

### 4.1 Data-Driven First

Use `Resource` objects as the primary source of gameplay definitions.

Do:

- define perk data in resources
- define enemy roles in resources
- define events in resources
- define skill behavior inputs in resources

Avoid:

- hardcoding large switch trees in UI scripts
- embedding content definitions directly inside scene controllers

### 4.2 Scene Authoring Friendly

Every major system should be compatible with designer-driven scene layout.

Do:

- expose `@export` node references
- allow drag-and-drop assignment in Inspector
- allow scenes to opt into systems through child nodes and resources

Avoid:

- assuming fixed paths like `get_node("CanvasLayer/RewardUI")` unless absolutely necessary

### 4.3 Logic Must Be Separate From UI

UI should display state and relay player choice.

UI should not:

- own gameplay calculations
- own permanent stat mutation
- directly determine encounter progression rules

Managers and gameplay systems should:

- validate choices
- apply modifiers
- calculate results

### 4.4 Shared Stats Must Be Centralized

Do not let multiple systems calculate final values independently.

Use a central stat layer such as `StatCalculator` or `RunManager`.

Examples:

- player final damage
- max HP
- projectile count
- enemy reward values
- cooldown modifiers

### 4.5 Prefer Signals Over Tight Coupling

Systems should communicate via signals where practical.

Recommended signals:

- `wave_cleared(wave_index)`
- `reward_selected(perk_id)`
- `skill_cast(skill_id)`
- `enemy_killed(enemy_data)`
- `relic_added(relic_id)`
- `event_finished(event_id)`

---

## 5. Recommended Folder Structure

```text
scripts/
  autoloads/
    autoload.gd
    run_manager.gd
    scene_manager.gd
    audio_manager.gd
  system/
    stat_calculator.gd
    encounter_manager.gd
  data/
    perk_data.gd
    skill_data.gd
    enemy_data.gd
    relic_data.gd
    event_data.gd
  ui/
    reward_ui.gd
    event_ui.gd
    skill_slot_ui.gd
  player/
    player.gd
    active_skill_component.gd
  enemy/
    base_enemy.gd
    enemy_brain.gd
    states/
  events/
    event_room.gd
  combat/
    wave_controller.gd
    spawn_controller.gd
    projectile.gd
    enemy_projectile.gd

assets/data/
  perks/
  skills/
  enemies/
  relics/
  events/
  waves/

scenes/
  ui/
  player/
  enemies/
  events/
  combat/
  exploration/
```

---

## 6. System Specifications

This section summarizes the 5 proposed advanced systems in implementation-ready form.

## 6.1 Wave Reward Draft System

### Objective

After each cleared wave, present the player with 3 reward choices and allow selection of 1 perk.

This system should:

- increase build variety
- create a meaningful reward loop between waves
- support balancing by changing data instead of rewriting logic

### Main Responsibilities

#### `RunManager`

- store selected perks and relics for the current run
- generate reward choices
- apply selected perk effects
- prevent illegal stacking or exclusivity violations

Suggested API:

- `get_reward_choices(count: int) -> Array[PerkData]`
- `apply_perk(perk: PerkData) -> void`
- `has_perk(id: StringName) -> bool`
- `get_total_modifier(stat_name: StringName) -> Variant`

#### `RewardUI`

- display choices
- emit the player selection
- never directly mutate combat stats

### Data Definition

`PerkData : Resource`

Suggested fields:

- `id: StringName`
- `title: String`
- `description: String`
- `rarity: int`
- `tags: Array[StringName]`
- `icon: Texture2D`
- `modifiers: Dictionary`
- `exclusive_with: Array[StringName]`
- `max_stack: int`

Example modifiers:

- `damage_multiplier = 0.2`
- `fire_rate_multiplier = 0.15`
- `pierce_bonus = 1`
- `lifesteal_flat = 3`

### Scene Integration

Each combat scene may include a manually placed reward UI node, for example:

- `CanvasLayer/RewardUI`

Wave flow:

1. wave ends
2. encounter pauses
3. reward UI opens with generated choices
4. player selects one reward
5. manager applies it
6. next wave begins

### High-Level Acceptance Criteria

- reward content is loaded from resources
- new perks can be added without editing UI code
- wave logic and reward presentation are decoupled

---

## 6.2 Active Skill Slot System

### Objective

Add one or more player-triggered active skills to complement auto-fire combat.

This system should:

- increase decision making
- reduce passive combat feel
- support future character builds and skill progression

### Main Responsibilities

#### `ActiveSkillComponent`

- hold currently equipped skill
- process input
- check cooldown
- execute the bound skill behavior

Suggested API:

- `equip_skill(skill_data: SkillData)`
- `can_cast() -> bool`
- `cast(target_data := {})`
- `get_cooldown_ratio() -> float`

#### Skill Executors

Each active skill should be implemented through reusable executors.

Examples:

- `dash_executor.gd`
- `pulse_bomb_executor.gd`
- `decoy_executor.gd`

### Data Definition

`SkillData : Resource`

Suggested fields:

- `id`
- `title`
- `description`
- `icon`
- `cooldown`
- `targeting_mode`
- `executor_scene` or `executor_script`
- `params: Dictionary`

Example params:

- Dash: `distance`, `duration`, `invincible`
- Pulse Bomb: `radius`, `damage`, `knockback`
- Decoy: `duration`, `hp`, `taunt_radius`

### Scene Integration

The player scene should include a manually placed `ActiveSkillComponent` child node.

It may also export references to:

- hurtbox
- movement controller
- animation player
- effect anchors

### High-Level Acceptance Criteria

- changing equipped skill should not require editing `player.gd`
- adding a new skill should mainly require a new resource and executor
- cooldown UI can be attached separately to the skill component

---

## 6.3 Enemy Roles System

### Objective

Expand enemy behavior from simple chase-contact damage to role-based combat archetypes.

This system should:

- create tactical priority
- increase encounter diversity
- allow more advanced wave composition

### Main Responsibilities

#### `BaseEnemy`

- read shared stats from `EnemyData`
- manage hurtbox and death flow
- expose references for AI and attacks

#### `EnemyBrain`

- choose active state
- track player target
- switch between chase, attack, retreat, recover, or special behavior

### Data Definition

`EnemyData : Resource`

Suggested fields:

- `id`
- `display_name`
- `max_hp`
- `move_speed`
- `contact_damage`
- `reward_gold`
- `role`
- `attack_cooldown`
- `aggro_range`
- `preferred_range`
- `projectile_scene`
- `special_params`

Example roles:

- `chaser`
- `shooter`
- `tank`
- `dasher`
- `summoner`

### AI States

Minimum suggested states:

- `SpawnState`
- `IdleState`
- `ChaseState`
- `AttackState`
- `RecoverState`
- `DeadState`

### Scene Integration

Each enemy scene should allow manual arrangement of:

- sprite
- collision
- hurtbox area
- muzzle point
- telegraph marker
- cast effect

Use exported references such as:

- `@export var muzzle: Node2D`
- `@export var telegraph: Node2D`

### Advanced Encounter Authoring

Wave definitions should evolve from simple counts into spawn entries containing:

- enemy type
- count
- delay
- spawn group
- spawn pattern

### High-Level Acceptance Criteria

- enemy role differences come mainly from data and brain logic
- new enemies can be created without duplicating all shared behavior
- encounter design becomes more expressive than simple quantity scaling

---

## 6.4 Curse Relic System

### Objective

Introduce relics that grant powerful benefits with meaningful drawbacks.

This system should:

- deepen builds
- create memorable run identities
- support risk/reward design

### Main Responsibilities

#### `RunManager`

- track relic ownership
- register modifiers
- expose triggered effects to runtime systems

#### `StatCalculator`

- calculate final gameplay values after all modifiers
- prevent fragmented stat logic across unrelated scripts

Suggested API examples:

- `get_player_damage(base_damage)`
- `get_player_max_hp(base_hp)`
- `get_enemy_reward(base_reward)`
- `get_projectile_count(base_count)`

### Data Definition

`RelicData : Resource`

Suggested fields:

- `id`
- `title`
- `description`
- `icon`
- `rarity`
- `positive_modifiers`
- `negative_modifiers`
- `triggers`
- `stackable`

Example modifiers:

- `damage_multiplier = +0.8`
- `max_hp_multiplier = -0.5`
- `enemy_speed_multiplier = +0.2`
- `gold_multiplier = +1.0`

Example triggers:

- `on_low_hp`
- `on_enemy_killed`
- `on_wave_start`
- `on_skill_cast`

### Scene Integration

Relics themselves do not require dedicated scenes.

However, methods of obtaining relics should be scene-based:

- shrine scene
- chest scene
- boss reward scene
- merchant scene

### High-Level Acceptance Criteria

- relic logic is composable with perk and shop bonuses
- final stat results are centralized
- relic acquisition can be embedded in different scene types

---

## 6.5 Event Room System

### Objective

Turn exploration spaces into meaningful gameplay by adding event-driven interactions.

This system should:

- increase risk/reward
- add narrative flavor
- improve route planning and replayability

### Main Responsibilities

#### `EventRoom`

- provide interactive entry point in scene
- determine whether this node uses fixed or random event selection
- open event UI
- forward chosen outcome to manager systems

#### `EventUI`

- display title, description, and choices
- report selected option
- avoid owning gameplay outcome resolution

### Data Definition

`EventData : Resource`

Suggested fields:

- `id`
- `title`
- `description`
- `weight`
- `tags`
- `choices: Array[EventChoiceData]`

`EventChoiceData`

- `id`
- `label`
- `description`
- `requirements`
- `effects`
- `next_event_id` optional

Example effects:

- lose HP
- gain gold
- receive relic
- start ambush fight
- heal player
- swap skill

### Scene Integration

Each exploration scene can include manually placed event nodes with:

- interaction area
- visuals
- prompt text
- VFX

Event selection modes:

- `fixed_event`
- `random_from_pool`

This supports both authored cinematic content and procedural roguelite content.

### High-Level Acceptance Criteria

- events are authored as data
- scene placement determines when and where they occur
- event outcomes resolve through shared managers rather than UI scripts

---

## 7. Scene Authoring Workflow

The intended workflow for this project is:

1. Designer creates a scene such as `FightScene`, `ExploreScene`, or `ShrineRoom`
2. Designer places nodes manually such as reward UI, spawn markers, triggers, and enemy anchors
3. Designer assigns data resources through Inspector such as wave sets, event pools, skill resources, and enemy definitions
4. Scripts interpret these resources and execute runtime logic automatically
5. New content is added by creating new resources or child scenes rather than rewriting the core framework

This is the correct workflow for a high-level game architecture:

- code builds the framework
- scenes build the player experience
- data builds content variety

---

## 8. Development Order

Recommended implementation sequence:

1. Build `RunManager`
2. Build `StatCalculator`
3. Move current hardcoded values into `Resource` definitions
4. Implement `Wave Reward Draft`
5. Implement `Active Skill Slot`
6. Implement `Enemy Roles`
7. Implement `Curse Relic`
8. Implement `Event Room`

Reason:

If the project has a solid runtime state manager, stat calculation layer, and data-driven content model first, all later systems become easier to implement cleanly.

---

## 9. Guidance For Agentic AI

Any AI agent working on this project should follow these constraints:

- preserve scene-driven authoring
- prefer exported node references over hardcoded node paths
- create reusable resources for gameplay data
- avoid mixing UI presentation with permanent gameplay state mutation
- centralize stat resolution
- prefer signals and APIs over direct scene coupling
- avoid large monolithic scripts when a component or executor pattern is more appropriate
- implement systems incrementally so current gameplay remains functional during refactors

Agents should treat this project as an advanced extensible game architecture, not as a short-term prototype with disposable code.

---

## 10. Executive Summary

This report defines a high-level Godot architecture for an advanced scene-driven, data-driven action game.

The 5 proposed systems are:

- Wave Reward Draft: data-driven perk choice after each wave
- Active Skill Slot: player-triggered abilities with executor-based behavior
- Enemy Roles System: reusable enemy archetypes powered by data and AI states
- Curse Relic System: high-impact reward items with tradeoffs and build identity
- Event Room System: exploration-based interactions that affect the run

All systems should be built on the same foundation:

- scene placement by the designer
- gameplay definitions in resources
- logic coordination through managers
- stat calculation through a central layer
- communication through signals and explicit APIs

This approach supports scalable development, rapid balancing, designer-friendly scene authoring, and advanced gameplay expansion without repeatedly rewriting core systems.
