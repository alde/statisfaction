<p align="center">
  <img src="media/icon.svg" width="96" alt="Statisfaction"/>
</p>

<h1 align="center">Statisfaction</h1>

<p align="center">Secondary stat priority for your spec and hero tree, with live diminishing returns. Get what you came for.</p>

---

## What it does

A small panel that shows the recommended secondary stat priority for your current specialization and active **Hero Talent Tree**, next to your live Crit / Haste / Mastery / Versatility numbers. Priorities follow the [method.gg](https://method.gg) guides (12.1).

By default the panel docks to the right of the Character panel and only shows while that is open. Detach it to keep it on screen (optionally only in combat).

It also tracks secondary stat diminishing returns (DR) in real time, and pushes a stat down the priority once it is past a DR bracket, so the banner always shows what to aim for *now*:

| Rating bonus | Penalty |
|---|---|
| 0% – 30% | none |
| 30% – 39% | 10% |
| 39% – 47% | 20% |
| 47% – 54% | 30% |
| 54% – 66% | 40% |
| > 66% | 50% |

## Commands

| Command | Action |
|---------|--------|
| `/statis` | Toggle the panel (opens the Character panel when docked) |
| `/statis config` | Open settings |
| `/statis dock` | Dock to / detach from the Character panel |
| `/statis lock` | Lock/unlock the detached panel |
| `/statis compact` | Toggle compact mode |
| `/statis reset` | Reset position |
| `/statis info` | Print spec, hero tree, priority and where it came from |

`/statisfaction` works too. Settings also live under *Options > AddOns > Statisfaction*.

## Priorities from other addons

Addons can supply their own priorities, which take precedence over the built-in table (OffBeat does this for its spec profiles):

```lua
if Statisfaction then
    Statisfaction:RegisterPriorityProvider("MyAddon", function(specId, heroTree)
        -- rank map: lower = higher priority. Equal = "=", gap < 1 = ">=", gap >= 1 = ">"
        return { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 }, "My Profile"
    end)
end
```

Return `nil` to fall through. Legacy strings like `"Haste > Crit = Mastery > Vers"` are accepted as well. Call `Statisfaction:RequestRefresh()` when your answer changes.

## Installation

From source: clone (or symlink) this repo into `Interface/AddOns/Statisfaction`, then fetch the libraries:

```bash
./download_deps.sh      # macOS/Linux
.\download_deps.ps1     # Windows
```

## License

MIT
