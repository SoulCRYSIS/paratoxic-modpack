-- local utils = require("prototypes.overhauls.overhual-utils")

-- local planet_technology = "planet-discovery-rubia"
-- if planet_technology then
--     utils.remove_tech(planet_technology, true, false)
-- end

-- for _, technology in pairs(data.raw.technology) do
--     local prerequisites = technology.prerequisites
--     if prerequisites then
--         for i = #prerequisites, 1, -1 do
--             if prerequisites[i] == planet_technology then
--                 table.remove(prerequisites, i)
--                 break
--             end
--         end
--     end
-- end

-- local technology = data.raw.technology[planet_technology]
-- if technology and technology.effects then
--     for _, effect in pairs(technology.effects) do
--         if effect.type == "unlock-recipe" then
--             data.raw.recipe[effect.recipe].enabled = true
--         end
--     end
-- end