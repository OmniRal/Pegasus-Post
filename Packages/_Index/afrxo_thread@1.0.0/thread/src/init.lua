--[[

    Simple coroutine based scheduler.

]]


--[=[

    @class Thread

    Compact coroutine based scheduler.

]=]
local Thread = {}


--[=[

    @function Spawn
    @within Thread
    @param Task thread | function
    @param ... ...any

    @return thread

    Calls/resumes the passed thread or function immediately.

]=]
function Thread.Spawn(Task, ...)
    local thread = nil
    if (type(Task) == "function") then
        thread = coroutine.create(Task)
    elseif (type(Task) == "thread") then
        thread = Task
    else
        error("Invalid task type")
    end

    coroutine.resume(thread, ...)
    return thread
end


--[=[

    @function After
    @within Thread
    @param Duration number
    @param Task thread | function

    Calls/resumes the passed thread or function after the given amount of time in seconds.

]=]
function Thread.After(Duration: number, Task, ...)
    task.delay(Duration, Task, ...)
end


--[=[

    @function Wait
    @within Thread
    @param Duration number

    Yields the current thread until the given amount of time in seconds has elapsed.

]=]
function Thread.Wait(Duration: number)
    return task.wait(Duration)
end


return Thread