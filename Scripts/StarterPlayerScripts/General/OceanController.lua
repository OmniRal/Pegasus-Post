-- OceanController with Vertex Colors
-- Replace your existing OceanController with this

local OceanController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local GRID_SIZE = 20             
local CHUNK_WORLD_SIZE = 200     
local WAVES = {
	{ Amplitude = 2.5,  Frequency = 0.08, Speed = 1.2,  DirX = 1,    DirZ = 0.3  },
	{ Amplitude = 1.2,  Frequency = 0.15, Speed = 0.9,  DirX = 0.5,  DirZ = 1    },
	{ Amplitude = 0.6,  Frequency = 0.25, Speed = 1.8,  DirX = -0.3, DirZ = 0.8  },
	{ Amplitude = 0.3,  Frequency = 0.40, Speed = 2.2,  DirX = 0.8,  DirZ = -0.5 },
}
local CHUNK_ORIGIN = Vector3.new(0, 15, 0)

-- Color palette for height mapping
local COLOR_DEEP = Color3.fromRGB(18, 109, 165)      -- Deep water (troughs)
local COLOR_MID = Color3.fromRGB(26, 129, 193)     -- Mid-level water
local COLOR_PEAK = Color3.fromRGB(143, 207, 250)   -- Foam (peaks)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local EditableMesh: EditableMesh
local VertexIDs = {}
local ColorIDs = {}  -- Store color IDs for each vertex

-- Track min/max wave heights for normalization
local MinWaveHeight = -5
local MaxWaveHeight = 5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetWaveHeight(X: number, Z: number, T: number)
	local Height = 0

	for _, Wave in ipairs(WAVES) do
		local Dot = X * Wave.DirX + Z * Wave.DirZ
		Height += Wave.Amplitude * math.sin(Dot * Wave.Frequency + T * Wave.Speed)
	end

	return Height
end

-- Calculate theoretical min/max wave heights
local function CalculateWaveRange()
	local totalAmplitude = 0
	for _, wave in ipairs(WAVES) do
		totalAmplitude += wave.Amplitude
	end
	MinWaveHeight = -totalAmplitude
	MaxWaveHeight = totalAmplitude
end

-- Map wave height to color (lerp between deep → mid → peak)
local function HeightToColor(height: number): Color3
	-- Normalize height to 0-1 range
	local normalized = (height - MinWaveHeight) / (MaxWaveHeight - MinWaveHeight)
	normalized = math.clamp(normalized, 0, 1)
	
	-- Two-stage gradient: deep→mid (0-0.5), mid→peak (0.5-1.0)
	if normalized < 0.5	 then
		local t = normalized * 2  -- 0-1 range for first half
		return COLOR_DEEP:Lerp(COLOR_MID, t)
	else
		local t = (normalized - 0.5) * 2  -- 0-1 range for second half
		return COLOR_MID:Lerp(COLOR_PEAK, t)
	end
end

local function Load()
	_G.OceanSurface = { GetWaveHeight = GetWaveHeight }
	
	CalculateWaveRange()

	-- Create EditableMesh
	EditableMesh = AssetService:CreateEditableMesh()

	-- Build vertices AND colors
	for Row = 0, GRID_SIZE do
		VertexIDs[Row] = {}
		ColorIDs[Row] = {}
		
		for Column = 0, GRID_SIZE do
			local X = (Column / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
			local Z = (Row / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
			
			-- Add vertex
			local VID = EditableMesh:AddVertex(Vector3.new(X, 0, Z))
			VertexIDs[Row][Column] = VID
			
			-- Add color for this vertex (start with mid color)
			local CID = EditableMesh:AddColor(COLOR_MID, 1.0)  -- color, alpha
			ColorIDs[Row][Column] = CID
		end
	end

	-- Build triangles with vertex colors
	for Row = 0, GRID_SIZE - 1 do
		for Column = 0, GRID_SIZE - 1 do
			local V00 = VertexIDs[Row][Column]
			local V10 = VertexIDs[Row + 1][Column]
			local V01 = VertexIDs[Row][Column + 1]
			local V11 = VertexIDs[Row + 1][Column + 1]
			
			local C00 = ColorIDs[Row][Column]
			local C10 = ColorIDs[Row + 1][Column]
			local C01 = ColorIDs[Row][Column + 1]
			local C11 = ColorIDs[Row + 1][Column + 1]

			-- Add triangles
			local FID1 = EditableMesh:AddTriangle(V00, V10, V01)
			local FID2 = EditableMesh:AddTriangle(V10, V11, V01)
			
			-- Assign colors to triangle vertices
			EditableMesh:SetFaceColors(FID1, {C00, C10, C01})
			EditableMesh:SetFaceColors(FID2, {C10, C11, C01})
		end
	end

	-- Create the mesh part
	local Mesh = AssetService:CreateMeshPartAsync(
		Content.fromObject(EditableMesh),
		{ CollisionFidelity = Enum.CollisionFidelity.Box }
	)

	Mesh.Name = "Ocean_Chunk_VertexColor"
	Mesh.Material = Enum.Material.Plastic
	Mesh.Color = Color3.fromRGB(255, 255, 255)  -- White base so vertex colors show pure
	Mesh.Transparency = 0
	Mesh.Anchored = true
	Mesh.CanCollide = false
	Mesh.CastShadow = false
	Mesh.Position = CHUNK_ORIGIN
	Mesh.Parent = Workspace
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function OceanController:Init()
	Load()

	RunService.Heartbeat:Connect(function()
		local T = tick()

		-- Update mesh vertices AND colors
		for Row = 0, GRID_SIZE do
			for Column = 0, GRID_SIZE do
				local VID = VertexIDs[Row][Column]
				local CID = ColorIDs[Row][Column]
				
				local X = (Column / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
				local Z = (Row / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
				local Y = GetWaveHeight(X, Z, T)

				-- Update position
				EditableMesh:SetPosition(VID, Vector3.new(X, Y, Z))
				
				-- Update color based on height
				local color = HeightToColor(Y)
				EditableMesh:SetColor(CID, color)
			end
		end
	end)
end

return OceanController