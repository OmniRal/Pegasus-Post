-- OmniRal

local AnimationController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

AnimationController.Tracks = {}
AnimationController.AnimTracks = {}

-----------------------------------------------------------------------------------------------------------------------------------------

-----------------
-- Private API --
-----------------

---------------------------------------------------------------------------------------------------------------------------------------

----------------
-- Public API --
----------------

-- Stops the animation track.
function AnimationController:CutAnim(KeyName: string)
    if self.AnimTracks[KeyName] then
        if self.AnimTracks[KeyName].T then
            self.AnimTracks[KeyName].T:Stop()
            self.AnimTracks[KeyName].T = nil
            self.AnimTracks[KeyName].CanPlay = true
        end
    end
end

-- Plays a new animation.
function AnimationController:PlayNew(Character: any, KeyName: string, AnimName: string, Override: boolean, Speed: number, KeyframeFunc: (string, string, {}?) -> (), ExtraKeyParams: {}?)
    if not Character or not self.Tracks[KeyName] or not self.AnimTracks[KeyName] then return end
    if not self.Tracks[KeyName][AnimName] then return end
    local Tracks = self.Tracks[KeyName]
    local AnimTrack = self.AnimTracks[KeyName]

    if AnimTrack.CanPlay or Override then
        if AnimTrack.T ~= nil then
            AnimTrack.T:Stop()
            AnimTrack.T = nil
        end

        if Tracks[AnimName].Track ~= nil then
            if not Tracks[AnimName].Set then
                Tracks[AnimName].Set = true

                Tracks[AnimName].Track.KeyframeReached:Connect(function(Keyframe: string)
                    KeyframeFunc(Keyframe, AnimName, ExtraKeyParams)
                end)
            end

            AnimTrack.T = Tracks[AnimName].Track
            AnimTrack.T:Play()
            AnimTrack.T:AdjustSpeed(Speed)
        end
    end
end

-- Load in all the animations when the player first spawns.
-- @Character: The character to load the animations onto.
-- @KeyName: The key name to be kept and used in the table.
-- @AnimationsList: The table of animations to load.
function AnimationController:LoadAnimations(Character: any, KeyName: string, AnimationsList: {[string]: {ID: number, Priority: Enum.AnimationPriority}})
	if not Character or not KeyName or not AnimationsList then return end
    self.Tracks[KeyName] = {}
    self.AnimTracks[KeyName] = {T = nil, CanPlay = true}

    for Name, Id in pairs(AnimationsList) do
        local NewAnimation = Instance.new("Animation")
        NewAnimation.AnimationId = "rbxassetid://" .. AnimationsList[Name].ID
        local NewTrack = Character.Humanoid:LoadAnimation(NewAnimation)
        NewTrack.Priority = AnimationsList[Name].Priority

        self.Tracks[KeyName][Name] = {Track = NewTrack, Set = false}
    end

    print("Loaded Animation Set: ", KeyName)
end

return AnimationController