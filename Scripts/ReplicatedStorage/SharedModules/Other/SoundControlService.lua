-- OmniRal

local SoundControlService = {}

local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoundControlService:PlaySoundWithRNG(Sound: Sound, Min: number, Max: number, Delay: number?, Volume: number?)
    if not Sound then return end
    if Volume then 
        Sound.Volume = Volume 
    end

    if Delay then
        task.delay(Delay, function()
            Sound.PlaybackSpeed = RNG:NextNumber(Min, Max)
            Sound:Play()
        end)
    else
        Sound.PlaybackSpeed = RNG:NextNumber(Min, Max)
        Sound:Play()
    end
end

function SoundControlService:TweenSoundVolume(Sound: Sound, GoalVolume: number, TweenTime: number, ReturnToOriginalVolume: boolean?, StopSoundAtZero: boolean?)
    if not Sound then return end
    
    local OriginalVolume = Sound.Volume

    if GoalVolume > 0 and not Sound.IsPlaying then
        Sound:Play()
    end

    local SoundTween = TweenService:Create(Sound, TweenInfo.new(TweenTime, Enum.EasingStyle.Linear), {Volume = GoalVolume})
    SoundTween.Completed:Connect(function()
        SoundTween = nil

        if ReturnToOriginalVolume then
            Sound.Volume = OriginalVolume
        end

        if StopSoundAtZero then
            Sound:Stop()
        end
    end)

    SoundTween:Play()
end

return SoundControlService