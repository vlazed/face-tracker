local mathparser = include("facetracker/shared/mathparser.lua")

local blendshapes = {
	"_neutral",
	"browDownLeft",
	"browDownRight",
	"browInnerUp",
	"browOuterUpLeft",
	"browOuterUpRight",
	"cheekPuff",
	"cheekSquintLeft",
	"cheekSquintRight",
	"eyeBlinkLeft",
	"eyeBlinkRight",
	"eyeLookDownLeft",
	"eyeLookDownRight",
	"eyeLookInLeft",
	"eyeLookInRight",
	"eyeLookOutLeft",
	"eyeLookOutRight",
	"eyeLookUpLeft",
	"eyeLookUpRight",
	"eyeSquintLeft",
	"eyeSquintRight",
	"eyeWideLeft",
	"eyeWideRight",
	"jawForward",
	"jawLeft",
	"jawOpen",
	"jawRight",
	"mouthClose",
	"mouthDimpleLeft",
	"mouthDimpleRight",
	"mouthFrownLeft",
	"mouthFrownRight",
	"mouthFunnel",
	"mouthLeft",
	"mouthLowerDownLeft",
	"mouthLowerDownRight",
	"mouthPressLeft",
	"mouthPressRight",
	"mouthPucker",
	"mouthRight",
	"mouthRollLower",
	"mouthRollUpper",
	"mouthShrugLower",
	"mouthShrugUpper",
	"mouthSmileLeft",
	"mouthSmileRight",
	"mouthStretchLeft",
	"mouthStretchRight",
	"mouthUpperUpLeft",
	"mouthUpperUpRight",
	"noseSneerLeft",
	"noseSneerRight",
	"tongueOut",
}

---@class ParserSystem
---@field private _parser Parser
---@field blendshapes string[]
local system = {
	_parser = mathparser:new(),
	blendshapes = blendshapes,
}

---@param expression string
---@return number
function system:solve(expression)
	return self._parser:solve(expression)
end

---@param coefficients {[FlexName]: number}?
function system:updateVariables(coefficients)
	coefficients = coefficients or {}
	for i, coefficient in ipairs(coefficients) do
		self._parser:addVariable(blendshapes[i], coefficient or 0)
	end
end

local default = {}
for i = 1, 53 do
	default[i] = 0
end
system:updateVariables(default)

FaceTracker.Parser = system
