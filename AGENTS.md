# AGENTS.md

## Core Directives

### 1. Anti-Overengineering & Just-In-Time Architecture

- **No Premature Abstraction**: Do NOT create intermediate layers, generic
  managers, registries, wrappers, or factory patterns without immediate,
  concrete need. Use idiomatic Lua/LÖVE 11 features: plain modules returning
  tables, metatable OOP (`X.__index = X`) only where a file already uses it,
  Concord ECS where entity simulation already lives.
- **Complexity Hard-Gate**: Complex, generic, or decoupled systems are
  STRICTLY FORBIDDEN unless explicitly mapped to a documented future
  development phase.

### 2. Player Experience Over Literal Implementation

- **Intent Interpretation**: Interpret user requests through intended player
  experience (gameplay feel, pacing, feedback, clarity, tension) rather than
  raw literal code architecture.
- **Mechanical Neutrality**: Do not judge mechanics as inherently "good" or
  "bad" in isolation. Mechanics derive value solely from the game loop and
  target dynamic.

### 3. Precedent Research Priority (Mechanics-First)

- **Mandatory Precedent Checks**: Resolve doubts about viability, feel,
  inputs, or parameters by researching established games.
- **Explicit Mechanical Focus**: Reference research MUST prioritize
  **MECHANICAL gameplay systems** (input response, projectile behavior,
  collision feedback, cooldown loops), NEVER thematic/narrative/visual
  aesthetics unless explicitly requested.

### 4. LÖVE 11 / Lua Conventions

- **Modules**: `local M = {}; return M` — locals by default, no globals
  outside deliberate shared tables. Mirror each file's existing style.
- **Entities**: Concord ECS for simulated actors (enemies, projectiles,
  hazards, the player inside real-time scenes); plain tables + metatables
  for scene/state objects (`Game`, `Battle`, `Campaign`). Composition over
  inheritance, always.
- **Communication Flow**: "Call down, emit up." Owners call into children
  directly; upward notification goes through `world:emit` / `game:effect`
  events consumed by presentation. No global event bus.
- **Data & Configuration**: Tunables live as named constants at the top of
  their module (`Game.weapons`, `Battle.*`, `Environment.constants`) —
  no config frameworks.
- **Loop**: `main.lua` is a thin dispatcher; simulation runs at fixed
  1/120 timestep; render reads state and never decides rules.

## Screenshots

Save all test screenshots/PNGs to `screenshots/` in the project root.
Capture via `--screenshot=screenshots/name.png` run from the root.
Never save prints to the root or `build/`.
