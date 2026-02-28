local utils = {}

local technologies = data.raw.technology

--- Removes a technology from the tech tree without deleting it.
---@param name string
---@param effects boolean Automatically enable the recipes from the technology's recipe unlocks.
---@param stitch boolean Stitch together the surrounding prerequisites and dependants in the tech tree.
function utils.remove_tech(name, effects, stitch)
  local technology = technologies[name]
  technology.hidden = true

  if effects and technology.effects then
      for _, effect in pairs(technology.effects) do
          if effect.type == "unlock-recipe" then
              local recipe = data.raw.recipe[effect.recipe]
              assert(recipe, "Recipe " .. effect.recipe .. " is nil. Please add it before data-final-fixes.")
              recipe.enabled = true
          end
      end
  end

  for _, tech in pairs(technologies) do
      local prerequisites = tech.prerequisites
      if not prerequisites then goto continue end

      for i = #prerequisites, 1, -1 do
          if prerequisites[i] == name then
              table.remove(prerequisites, i)
              if stitch and technology.prerequisites then
                  for _, prereq in pairs(technology.prerequisites) do
                      prerequisites[#prerequisites+1] = prereq
                  end
              end
              break
          end
      end

      ::continue::
  end

  technology.prerequisites = nil
end

return utils