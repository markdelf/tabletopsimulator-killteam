--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    --[[ printToAll('onLoad!') --]]
   math.randomseed(os.time())
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ printToAll('onUpdate loop!') --]]
end

local toHitSkill = 4
local numOfAttacks = 1
local hitMemory = 0
local woundMemory = 0

local isObstructed = false
local isLongRange = false
local injuryLevel = 0

local attackStrength = 3
local targetToughness = 3

function hideAnyPanels()
    hideWoundPanel()
    hideHitPanel()
    UI.setAttribute('cancel', "active", false)
    UI.setAttribute("backButton", "active", false)
    UI.setAttribute('start', "active", true)
end

function showHitPanel()
  hideAnyPanels()
  setAttacks(numOfAttacks)
  setToHit(toHitSkill)
  setInjuryLevel(injuryLevel)
  setIsLongRange(isLongRange)
  setIsObstructed(isObstructed)
  UI.setAttribute('toHitPanel', "active", true)
  UI.setAttribute('cancel', "active", true)
  UI.setAttribute('start', "active", false)
end

function hideHitPanel()
  UI.setAttribute('toHitPanel', "active", false)
end

function showWoundPanel()
  hideAnyPanels()
  setAttackStrength(attackStrength)
  setTargetToughness(targetToughness)
  setHitMemory(hitMemory);
  UI.setAttribute('toWoundPanel', "active", true)
  UI.setAttribute("backButton", "active", true)
  UI.setAttribute('cancel', "active", true)
  UI.setAttribute('start', "active", false)
end

function hideWoundPanel()
  UI.setAttribute('toWoundPanel', "active", false)
end

function onHitRoll(player)
  printToAll("")
  printToAll(player.color .. " player rolling to hit")

  local modifier = getHitModifier(isLongRange, isObstructed, injuryLevel)
  doHitRoll(numOfAttacks, toHitSkill, modifier)
  if hitMemory == 0 then
    hideAnyPanels()
  else
    showWoundPanel()
  end
end

function onWoundRoll(player)
  printToAll("")
  printToAll(player.color .. " player rolling to wound")
  if hitMemory == 0 then
    printToAll("No hits!")
  else
      doWouldRoll(hitMemory, attackStrength, targetToughness, 0)
  end
end

function onToggleInjury(player, value, id)
  if id == "isInjury0" then
    injuryLevel = 0
  elseif id == "isInjury1" then
    injuryLevel = 1
  elseif id == "isInjury2" then
    injuryLevel = 2
  end
end

function onToggleObstructed(player, value, id)
  isObstructed = value
end

function onToggleLongRange(player, value, id)
  isLongRange = value
end

function addAttacks()
  local newAttacks = numOfAttacks + 1
  setAttacks(newAttacks)
end

function subAttacks()
  local newAttacks = numOfAttacks - 1
  if newAttacks < 1 then
    newAttacks = 1
  end
  setAttacks(newAttacks)
end

function setAttacks(attacks)
  numOfAttacks = attacks
  UI.setAttribute('numOfAttacks', "text", "<b>" .. numOfAttacks .. "</b> attacks")
end

function addToHitSkill()
  local newToHit = toHitSkill + 1
  setToHit(newToHit)
end

function subToHitSkill()
  local newToHit = toHitSkill - 1
  if newToHit < 1 then
    newToHit = 1
  end
  setToHit(newToHit)
end

function setToHit(toHit)
  toHitSkill = toHit
  UI.setAttribute('toHitSkill', "text", "<b>" .. toHitSkill .. "+</b> BS/WS")
end

function setInjuryLevel(level)
  injuryLevel = level
  UI.setAttribute('isInjury0', "isOn", injuryLevel == 0)
  UI.setAttribute('isInjury1', "isOn", injuryLevel == 1)
  UI.setAttribute('isInjury2', "isOn", injuryLevel == 2)
end

function setIsObstructed(obstructed)
  isObstructed = obstructed
  UI.setAttribute('isObstructed', "isOn", isObstructed)
end

function setIsLongRange(longRange)
  isLongRange = longRange
  UI.setAttribute('isLongRange', "isOn", longRange)
end

function doHitRoll(attacks, toHit, modifier)
  printToAll("   Rolling " .. attacks .. "xD6")

  local results = rollDice(attacks)
  printToAll("      Natural Results: " .. table.concat(results, ","))

  local modified = applyModifier(results, modifier)
  if modifier != 0 then
    printToAll("      Modified Results: " .. table.concat(modified, ","))
  end

  local successes = {}
  for i in pairs(modified) do
     if modified[i] >= toHit then
       table.insert(successes, modified[i])
     end
  end

  printToAll("")
  if #successes > 0 then
    printToAll(#successes .. " hits (" .. table.concat(successes, ",") .. ")")
  else 
    printToAll("No hits!")
  end
  setHitMemory(#successes);
end

function doWouldRoll(hits, strength, toughness, modifier)
  printToAll("   Rolling " .. hits .. "xD6")
  
  local results = rollDice(hits)
  printToAll("      Natural Results: " .. table.concat(results, ","))

  local modified = applyModifier(results, modifier)
  if modifier != 0 then
    printToAll("      Modified Results: " .. table.concat(modified, ","))  
  end

  local toWound = getToWound(strength, toughness)
  local successes = {}
  for i in pairs(modified) do
     if modified[i] >= toWound then
       table.insert(successes, modified[i])
     end
  end

  printToAll("")
  if #successes > 0 then
    printToAll(#successes .. " wounds (" .. table.concat(successes, ",") .. ")")
  else 
    printToAll("No wounds!")
  end
  woundMemory = #successes
end

function rollDice(qty)
  local results = {}
  for i = 1, qty do
    results[i] = rollDie(6)
  end
  return results
end

function applyModifier(results, modifier)
  local modified = {}
  for i in pairs(results) do
      table.insert(modified, results[i] + modifier)
  end
  return modified
end

function rollDie(dieSize)
   return math.ceil(math.random() * dieSize)
end

function getHitModifier(isLongRange, isObstructed, numberOfInjuries)
  local modifier = 0
  if isLongRange and isLongRange != "false" and isLongRange != "False" then
    modifier = modifier - 1
  end
  if isObstructed and isObstructed != "false" and isObstructed != "False" then
    modifier = modifier - 1
  end
  modifier = modifier - (1 * numberOfInjuries)
  return modifier
end

function getToWound(strength, toughness)
  if strength == toughness then 
    return 4
  elseif strength >= (toughness * 2) then
    return 2
  elseif strength <= (toughness / 2) then
    return 6
  elseif strength > toughness then
    return 3
  elseif strength < toughness then
    return 5
  end
end

function addHitMemory()
  local hits = hitMemory + 1
  setHitMemory(hits)
end

function subHitMemory()
  local hits = hitMemory - 1
  if hits < 1 then
    hits = 1
  end
  setHitMemory(hits)
end

function setHitMemory(hits)
  hitMemory = hits
  UI.setAttribute('hitMemory', "text", "Hits: <b>" .. hitMemory .. "</b>")
end

function addAttackStrength()
  local strength = attackStrength + 1
  setAttackStrength(strength)
end

function subAttackStrength()
  local strength = attackStrength - 1
  if strength < 1 then
    strength = 1
  end
  setAttackStrength(strength)
end

function setAttackStrength(strength)
  attackStrength = strength
  UI.setAttribute('attackStrength', "text", "Attack strength: <b>" .. attackStrength .. "</b>")
end


function addTargetToughness()
  local toughness = targetToughness + 1
  setTargetToughness(toughness)
end

function subTargetToughness()
  local toughness = targetToughness - 1
  if toughness < 1 then
    toughness = 1
  end
  setTargetToughness(toughness)
end

function setTargetToughness(toughness)
  targetToughness = toughness
  UI.setAttribute('targetToughness', "text", "Target toughness: <b>" .. targetToughness .. "</b>")
end

function back()
  local woundPanelVisible = UI.getAttribute('toWoundPanel', "active")
  if (woundPanelVisible) then
    hideWoundPanel()
    showHitPanel()
    UI.setAttribute("backButton", "active", false)
  end
end
