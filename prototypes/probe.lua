-- Paratoxic Probe: AI-themed spidertron for surface deployment from mainframe
-- Uses locked equipment grid to prevent item duping

-- Locked equipment grid for probe (prevents moving equipment/bots)
data:extend({
  {
    type = "equipment-grid",
    name = "paratoxic-probe-equipment-grid",
    width = 10,
    height = 6,
    locked = true,
    equipment_categories = { "armor" }
  }
})

-- Probe spidertron (copy from base spidertron, use our locked grid)
local spidertron = data.raw["spider-vehicle"]["spidertron"]
if spidertron then
  local probe = util.table.deepcopy(spidertron)
  probe.name = "paratoxic-probe"
  probe.equipment_grid = "paratoxic-probe-equipment-grid"
  probe.minable = nil -- Prevent mining to avoid duping
  probe.max_health = spidertron.max_health
  probe.localised_name = { "entity-name.paratoxic-probe" }
  probe.localised_description = { "entity-description.paratoxic-probe" }
  data:extend({ probe })
end

-- Surface swap shortcut (teleport between mainframe and probes)
data:extend({
  {
    type = "shortcut",
    name = "paratoxic-surface-swap",
    action = "lua",
    localised_name = { "shortcut-name.paratoxic-surface-swap" },
    localised_description = { "shortcut-description.paratoxic-surface-swap" },
    icon = "__base__/graphics/icons/spidertron.png",
    icon_size = 64,
    small_icon = "__base__/graphics/icons/spidertron.png",
    small_icon_size = 24,
  }
})
