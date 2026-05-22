# Contraband Warning

Contraband Warning is a Dynamic SS13 Module that adds a red examine warning to
items designated as contraband.

By default, it warns on item paths sold by the traitor uplink when those uplink
items use `SYNDIE_TRIPS_CONTRABAND`. The warning is only shown to security HUD
users unless configured otherwise.

## Configuration

Defaults live in `config/default.toml` and can be overridden by the host at:

```text
config/dynamic_modules/contraband-warning.toml
```

Example override:

```toml
require_security_hud = false

[[contraband]]
path = "/obj/item/stack/telecrystal"
include_children = true
level = "Syndicate"

[[exemptions]]
path = "/obj/item/toy/cards/deck/syndicate"
include_children = false
```

## Integration

The module defines:

- `/datum/controller/subsystem/dynamic_contraband_warning`
- `/datum/component/contraband_warning`

The subsystem attaches the component to matching existing items during init and
to newly-created items through `COMSIG_GLOB_NEW_ITEM`.
