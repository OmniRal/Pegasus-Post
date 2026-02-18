-- OceanController with Shore Detection
-- Uses CollectionService to detect "ShoreSand" tagged parts

local OceanController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local GRID_SIZE = 40   
local CHUNK_WORLD_SIZE = 1000     
local WAVES = {
	-- Large, slow swells (the primary rolling motion)
	{ Amplitude = 3.0,  Frequency = 0.06, Speed = 0.8,  DirX = 1,    DirZ = 0.2,  Phase = 0 },
	{ Amplitude = 2.2,  Frequency = 0.08, Speed = 1.0,  DirX = 0.3,  DirZ = 1,    Phase = 1.5 },
	
	-- Medium waves (secondary motion, different directions)
	{ Amplitude = 1.5,  Frequency = 0.12, Speed = 1.3,  DirX = -0.5, DirZ = 0.8,  Phase = 3.2 },
	{ Amplitude = 1.2,  Frequency = 0.15, Speed = 0.9,  DirX = 0.7,  DirZ = -0.6, Phase = 2.1 },
	
	-- Smaller chop (creates texture and variety)
	{ Amplitude = 0.8,  Frequency = 0.22, Speed = 1.8,  DirX = 0.9,  DirZ = 0.4,  Phase = 4.7 },
	{ Amplitude = 0.6,  Frequency = 0.28, Speed = 2.0,  DirX = -0.3, DirZ = -0.9, Phase = 1.8 },
	
	-- Fine detail (high frequency ripples)
	{ Amplitude = 0.4,  Frequency = 0.35, Speed = 2.3,  DirX = 0.6,  DirZ = 0.8,  Phase = 5.4 },
	{ Amplitude = 0.3,  Frequency = 0.42, Speed = 2.6,  DirX = -0.7, DirZ = 0.5,  Phase = 3.9 },
}
local CHUNK_ORIGIN = Vector3.new(0, 15, 0)

-- Ocean color palette (deep water)
local COLOR_DEEP = Color3.fromRGB(18, 109, 165)
local COLOR_MID = Color3.fromRGB(26, 129, 193)
local COLOR_PEAK = Color3.fromRGB(143, 207, 250)

-- Shore color palette (shallow water, turquoise)
local SHORE_COLOR_DEEP = Color3.fromRGB(199, 240, 255)    -- Lighter, more turquoise
local SHORE_COLOR_MID = Color3.fromRGB(217, 245, 255)
local SHORE_COLOR_PEAK = Color3.fromRGB(233, 249, 255)   -- Almost white foam

-- Shore detection settings
local SHORE_DETECTION_DISTANCE = 25  -- How far out from shore to apply effect (studs)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local EditableMesh: EditableMesh
local VertexIDs = {}
local ColorIDs = {}
local LayerMeshes = {}

-- Shore detection cache
local ShoreParts = {}  -- Cached shore part data

local MinWaveHeight = -5
local MaxWaveHeight = 5

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function GetWaveHeight(X: number, Z: number, T: number, shoreDistance: number?)
	local Height = 0
	
	-- Calculate wave dampening factor based on shore proximity
	local dampenFactor = 1.0
	if shoreDistance and shoreDistance < SHORE_DETECTION_DISTANCE then
		local t = shoreDistance / SHORE_DETECTION_DISTANCE
		dampenFactor = 0.1 + (0.9 * (t * t))  -- Quadratic ease for smooth transition
	end
	
	-- === NEW: Wave intensity modulation ===
	-- Creates patches of calm and active water across the ocean
	-- Uses very low frequency noise patterns that move slowly
	local intensityScale = 0.02  -- Very low frequency = large patches
	local intensitySpeed = 0.15  -- Slow movement
	
	-- Two layers of intensity modulation at different scales
	local intensity1 = math.sin(X * intensityScale + T * intensitySpeed) * 
	                   math.sin(Z * intensityScale + T * intensitySpeed * 0.7)
	local intensity2 = math.sin(X * intensityScale * 1.3 + T * intensitySpeed * 0.8) * 
	                   math.sin(Z * intensityScale * 1.3 - T * intensitySpeed * 0.6)
	
	-- Combine and map to 0.3 - 1.0 range
	-- (never completely flat, just calmer patches)
	local intensityFactor = 0.5 + (intensity1 * 0.25) + (intensity2 * 0.25)
	intensityFactor = math.clamp(intensityFactor, 0.3, 1.0)

	for _, Wave in ipairs(WAVES) do
		local Dot = X * Wave.DirX + Z * Wave.DirZ
		-- Apply both shore dampening AND intensity modulation
		local amplitude = Wave.Amplitude * dampenFactor * intensityFactor
		Height += amplitude * math.sin(Dot * Wave.Frequency + T * Wave.Speed + Wave.Phase)
	end

	return Height
end

local function CalculateWaveRange()
	local totalAmplitude = 0
	for _, wave in ipairs(WAVES) do
		totalAmplitude += wave.Amplitude
	end
	MinWaveHeight = -totalAmplitude
	MaxWaveHeight = totalAmplitude
end

-- Cache shore parts at initialization
local function CacheShoreFrontFaces()
	task.wait(0.5)  -- Allow workspace to populate
	local shoreParts = CollectionService:GetTagged("ShoreSand")
	
	for _, sand in ipairs(shoreParts) do
		table.insert(ShoreParts, {
			CFrame = sand.CFrame,
			Size = sand.Size,
		})
	end
	
	print("[Ocean] Cached", #ShoreParts, "shore detection zones")
end

-- Get distance from vertex to nearest edge of any shore part
local function GetShoreDistance(vertexPos: Vector3)
	local closestDistance = math.huge
	
	for _, shore in ipairs(ShoreParts) do
		-- Transform vertex position into shore part's local space
		local localPos = shore.CFrame:PointToObjectSpace(vertexPos)
		
		-- Calculate distance to the part's surface (not center)
		-- If inside the part, distance is negative
		local halfSize = shore.Size * 0.5
		
		-- Distance from each face
		local dx = math.max(0, math.abs(localPos.X) - halfSize.X)
		local dy = math.max(0, math.abs(localPos.Y) - halfSize.Y)
		local dz = math.max(0, math.abs(localPos.Z) - halfSize.Z)
		
		-- If point is inside the bounds in XZ, distance is just vertical
		-- Otherwise, it's the distance to nearest corner/edge
		local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
		
		closestDistance = math.min(closestDistance, distance)
	end
	
	return closestDistance
end

-- Map wave height to color using deep ocean palette
local function HeightToColor(height: number): Color3
	local normalized = (height - MinWaveHeight) / (MaxWaveHeight - MinWaveHeight)
	normalized = math.clamp(normalized, 0, 1)
	
	if normalized < 0.5 then
		local t = normalized * 2
		return COLOR_DEEP:Lerp(COLOR_MID, t)
	else
		local t = (normalized - 0.5) * 2
		return COLOR_MID:Lerp(COLOR_PEAK, t)
	end
end

-- Simple Perlin-style noise function
-- Returns value between -1 and 1
local function Noise2D(x: number, z: number): number
	-- Simple hash-based pseudo-random noise
	local n = math.sin(x * 12.9898 + z * 78.233) * 43758.5453
	return (n - math.floor(n)) * 2 - 1  -- Map to -1 to 1
end

-- Smooth ease-in-out curve (non-linear falloff)
local function EaseInOutQuad(t: number): number
	if t < 0.5 then
		return 2 * t * t
	else
		return 1 - math.pow(-2 * t + 2, 2) / 2
	end
end

-- Map wave height to color using shore palette
local function HeightToColor_Shore(height: number): Color3
	local normalized = (height - MinWaveHeight) / (MaxWaveHeight - MinWaveHeight)
	normalized = math.clamp(normalized, 0, 1)
	
	if normalized < 0.5 then
		local t = normalized * 2
		return SHORE_COLOR_DEEP:Lerp(SHORE_COLOR_MID, t)
	else
		local t = (normalized - 0.5) * 2
		return SHORE_COLOR_MID:Lerp(SHORE_COLOR_PEAK, t)
	end
end

local function Load()
	_G.OceanSurface = { GetWaveHeight = GetWaveHeight }
	
	CalculateWaveRange()
	task.delay(2, function()
		CacheShoreFrontFaces()
	
	end)

	-- Create EditableMesh
	EditableMesh = AssetService:CreateEditableMesh()

	-- Build vertices AND colors
	for Row = 0, GRID_SIZE do
		VertexIDs[Row] = {}
		ColorIDs[Row] = {}
		
		for Column = 0, GRID_SIZE do
			local X = (Column / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
			local Z = (Row / GRID_SIZE - 0.5) * CHUNK_WORLD_SIZE
			
			local VID = EditableMesh:AddVertex(Vector3.new(X, 0, Z))
			VertexIDs[Row][Column] = VID
			
			local CID = EditableMesh:AddColor(COLOR_MID, 1.0)
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

			local FID1 = EditableMesh:AddTriangle(V00, V10, V01)
			local FID2 = EditableMesh:AddTriangle(V10, V11, V01)
			
			EditableMesh:SetFaceColors(FID1, {C00, C10, C01})
			EditableMesh:SetFaceColors(FID2, {C10, C11, C01})
		end
	end

	local Layers = {
		{Color = Color3.fromRGB(159, 111, 255), Material = Enum.Material.Glass, Transparency = 0.5, OffsetY = 0, AddSA = true},
		{Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Glass, Transparency = 0.15, OffsetY = -1, AddSA = false},
		{Color = Color3.fromRGB(40, 59, 52), Material = Enum.Material.Plastic, Transparency = 0.75, OffsetY = -2, AddSA = false},
		{Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, Transparency = 0, OffsetY = -3, AddSA = false},
	}

	for x = 1, #Layers do
		local Mesh = AssetService:CreateMeshPartAsync(
			Content.fromObject(EditableMesh),
			{ CollisionFidelity = Enum.CollisionFidelity.Box }
		)

		Mesh.Name = "Ocean_Chunk_VertexColor"
		Mesh.Color = Layers[x].Color
		Mesh.Material = Layers[x].Material
		Mesh.Transparency = Layers[x].Transparency
		Mesh.Anchored = true
		Mesh.CanCollide = false
		Mesh.CastShadow = false
		Mesh.Position = CHUNK_ORIGIN + Vector3.new(0, Layers[x].OffsetY)

		if Layers[x].AddSA then
			local SA = Instance.new("SurfaceAppearance")
			SA.AlphaMode = Enum.AlphaMode.Overlay
			SA.Parent = Mesh
		end

		Mesh.Parent = Workspace
		LayerMeshes[x] = Mesh
	end

	-- Layer breathing animation
	RunService.Heartbeat:Connect(function()
		local T = tick()
		
		for i, mesh in ipairs(LayerMeshes) do
			local baseOffset = Layers[i].OffsetY
			local speed = 0.3 - (i * 0.05)
			local amplitude = 0.1 + (i * 0.05)
			local phase = i * 0.5
			
			local animatedOffset = amplitude * math.sin(T * speed + phase)
			mesh.Position = CHUNK_ORIGIN + Vector3.new(0, baseOffset + animatedOffset, 0)
		end
	end)
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
				
				-- Check distance to nearest shore first (needed for both waves and colors)
				local shoreDistance = GetShoreDistance(Vector3.new(X, 0, Z))
				
				-- Calculate wave height WITH shore dampening
				local Y = GetWaveHeight(X, Z, T, shoreDistance)

				-- Update position
				EditableMesh:SetPosition(VID, Vector3.new(X, Y, Z))
				
				local color
				if shoreDistance < SHORE_DETECTION_DISTANCE then
					-- === EFFECT 1: Add Perlin noise to make edge organic ===
					-- Sample noise at this XZ position (scale controls frequency)
					local noiseScale = 0.1  -- Smaller = larger noise features
					local noiseValue = Noise2D(X * noiseScale, Z * noiseScale)
					
					-- Modulate the detection distance with noise
					-- This makes the foam edge wavy instead of perfectly circular
					local noiseInfluence = 5  -- How many studs the noise can push/pull
					local modulatedDistance = shoreDistance + (noiseValue * noiseInfluence)
					
					-- === EFFECT 2: Wave height modulation ===
					-- Normalize wave height to 0-1 range
					local waveHeightNormalized = (Y - MinWaveHeight) / (MaxWaveHeight - MinWaveHeight)
					
					-- High waves push foam further out, low waves pull it back
					local waveInfluence = 8  -- How many studs waves can extend foam
					local waveOffset = (waveHeightNormalized - 0.5) * waveInfluence
					modulatedDistance = modulatedDistance - waveOffset
					
					-- === EFFECT 3: Non-linear falloff (ease-in-out) ===
					-- Calculate base blend factor (0 = shore, 1 = ocean)
					local linearBlend = math.clamp(modulatedDistance / SHORE_DETECTION_DISTANCE, 0, 1)
					
					-- Apply smooth ease curve instead of linear
					local blendFactor = EaseInOutQuad(linearBlend)
					
					-- Final color blend
					local shoreColor = HeightToColor_Shore(Y)
					local oceanColor = HeightToColor(Y)
					color = shoreColor:Lerp(oceanColor, blendFactor)
				else
					-- Deep ocean
					color = HeightToColor(Y)
				end
				
				EditableMesh:SetColor(CID, color)
			end
		end
	end)
end

return OceanController