local OceanController = {}

-- OceanChunk.lua
-- Place in StarterPlayerScripts as a LocalScript
-- Pegasus Post — Wave Mesh v2 (correct API)

local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")

-- ─────────────────────────────────────────
-- CHUNK CONFIGURATION
-- ─────────────────────────────────────────
local CONFIG = {
	GRID_SIZE = 20,             -- vertices per side (raise later for smoother waves)
	CHUNK_WORLD_SIZE = 200,     -- size of this chunk in studs
	WAVES = {
		{ amplitude = 2.5,  frequency = 0.08, speed = 1.2,  dirX = 1,    dirZ = 0.3  },
		{ amplitude = 1.2,  frequency = 0.15, speed = 0.9,  dirX = 0.5,  dirZ = 1    },
		{ amplitude = 0.6,  frequency = 0.25, speed = 1.8,  dirX = -0.3, dirZ = 0.8  },
		{ amplitude = 0.3,  frequency = 0.40, speed = 2.2,  dirX = 0.8,  dirZ = -0.5 },
	},
	CHUNK_ORIGIN = Vector3.new(0, 0, 0),
}

-- ─────────────────────────────────────────
-- WAVE HEIGHT FUNCTION
-- Exposed globally for boat physics later
-- ─────────────────────────────────────────
local function getWaveHeight(x, z, t)
	local height = 0
	for _, wave in ipairs(CONFIG.WAVES) do
		local dot = x * wave.dirX + z * wave.dirZ
		height += wave.amplitude * math.sin(dot * wave.frequency + t * wave.speed)
	end
	return height
end

_G.OceanSurface = { getWaveHeight = getWaveHeight }

-- ─────────────────────────────────────────
-- BUILD THE EDITABLE MESH
-- FixedSize = true means we can update vertex
-- positions each frame without rebuilding triangles
-- ─────────────────────────────────────────
local editableMesh = AssetService:CreateEditableMesh()

local N = CONFIG.GRID_SIZE
local worldSize = CONFIG.CHUNK_WORLD_SIZE

-- Store vertex IDs for the update loop
local vertexIDs = {}

for row = 0, N do
	vertexIDs[row] = {}
	for col = 0, N do
		local x = (col / N - 0.5) * worldSize
		local z = (row / N - 0.5) * worldSize
		local vID = editableMesh:AddVertex(Vector3.new(x, 0, z))
		vertexIDs[row][col] = vID
	end
end

-- Build triangles — done once, never touched again
for row = 0, N - 1 do
	for col = 0, N - 1 do
		local v00 = vertexIDs[row][col]
		local v10 = vertexIDs[row + 1][col]
		local v01 = vertexIDs[row][col + 1]
		local v11 = vertexIDs[row + 1][col + 1]

		editableMesh:AddTriangle(v00, v10, v01)
		editableMesh:AddTriangle(v10, v11, v01)
	end
end

-- ─────────────────────────────────────────
-- CREATE THE MESHPART AND BIND
-- ─────────────────────────────────────────
local meshPart = AssetService:CreateMeshPartAsync(
	Content.fromObject(editableMesh),
	{ CollisionFidelity = Enum.CollisionFidelity.Box }
)
meshPart.Name = "OceanChunk"
meshPart.Anchored = true
meshPart.CanCollide = true
meshPart.CastShadow = false
meshPart.Position = CONFIG.CHUNK_ORIGIN
meshPart.Parent = workspace

-- ─────────────────────────────────────────
-- UPDATE LOOP — move vertices each frame
-- SetPosition is the correct current API
-- ─────────────────────────────────────────

function OceanController:Init()
RunService.Heartbeat:Connect(function()
	local t = tick()

	for row = 0, N do
		for col = 0, N do
			local vID = vertexIDs[row][col]
			local x = (col / N - 0.5) * worldSize
			local z = (row / N - 0.5) * worldSize
			local y = getWaveHeight(x, z, t)

			editableMesh:SetPosition(vID, Vector3.new(x, y, z))
		end
	end
end)
end

return OceanController