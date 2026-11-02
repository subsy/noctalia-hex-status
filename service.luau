--!nonstrict
-- Headless poller shared by every bar instance. Hex has no status stream, so
-- this polls `hex status --json` and publishes a small view of it to
-- noctalia.state only when that view changes (state.set notifies on equal values).

local STALE_MS = 5000 -- a call with no callback by then is treated as lost

local inflightSince = nil
local lastRaw = nil
local lastId = nil

local function classify(s)
    if s == nil then return "down" end
    local capture, model = s.capture or {}, s.model or {}
    if capture.state == "recording" then
        return capture.recording == "meeting" and "meeting" or "recording"
    end
    -- Any other non-idle state (processing, transcribing, pasting) is work in progress.
    if capture.state ~= "idle" or (tonumber(capture.pending_jobs) or 0) > 0 then return "working" end
    if not (s.listener and s.listener.running) then return "disabled" end
    if model.error then return "attention" end
    if model.preparing or not model.installed then return "preparing" end
    if s.permissions and s.permissions.ready == false then return "attention" end
    return "idle"
end

local function publish(s)
    local model = s and s.model or {}
    local view = {
        key = classify(s),
        model = model.name,
        error = model.error and tostring(model.error) or nil,
        meeting = s and s.meeting and s.meeting.title or nil,
        update = s ~= nil and s.update == "available",
    }
    local id = noctalia.json.encode(view)
    if id == lastId then return end
    lastId = id
    noctalia.state.set("status", view)
end

local function poll()
    local now = noctalia.nowMs()
    if inflightSince and now - inflightSince < STALE_MS then return end
    inflightSince = now
    local started = noctalia.runAsync("hex status --json", function(result)
        inflightSince = nil
        -- Exit code 3 means Hex isn't running.
        local ok = result ~= nil and not result.timedOut and result.exitCode == 0
        if ok and result.stdout == lastRaw then return end
        lastRaw = ok and result.stdout or nil
        local status = ok and noctalia.json.decode(result.stdout or "") or nil
        publish(type(status) == "table" and status or nil)
    end)
    if not started then inflightSince = nil end
end

function update() poll() end

if noctalia.commandExists("hex") then
    noctalia.setUpdateInterval(math.max(100, tonumber(noctalia.getConfig("poll_ms")) or 300))
    poll()
else
    noctalia.state.set("status", { key = "missing" })
end
