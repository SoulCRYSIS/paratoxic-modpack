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
local probe = table.deepcopy(data.raw["spider-vehicle"]["ss-space-spidertron"])
probe.name = "paratoxic-probe"
probe.equipment_grid = "paratoxic-probe-equipment-grid"
probe.minable = nil -- Prevent mining to avoid duping
probe.localised_name = { "entity-name.paratoxic-probe" }
probe.localised_description = { "entity-description.paratoxic-probe" }
probe.allow_remote_driving = true
data:extend({ probe })

local technology = data.raw["technology"]["spidertron"]
local new_effects = {}
for _, effect in ipairs(technology.effects) do
  if effect.recipe ~= "ss-space-spidertron" then
    table.insert(new_effects, effect)
  end
end
technology.effects = new_effects

data.raw["spider-vehicle"]["ss-space-spidertron"].hidden = true
data.raw["recipe"]["ss-space-spidertron"].hidden = true
