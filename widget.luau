--!nonstrict
-- Bar capsule for Hex; the poller service owns the `hex status` calls.

local SHOW_LABEL = noctalia.getConfig("show_label") == true

local LOOKS = { -- key -> glyph, color (nil = bar default)
    idle = { "microphone" },
    recording = { "microphone-filled", "error" },
    meeting = { "users", "error" },
    working = { "loader", "primary" },
    preparing = { "download", "secondary" },
    disabled = { "microphone-off", "on_surface_variant" },
    attention = { "microphone-off", "secondary" },
    down = { "microphone-off", "error" },
    missing = { "microphone-off", "error" },
}

local function render()
    local view = noctalia.state.get("status") or { key = "down" }
    local look = LOOKS[view.key] or LOOKS.down
    local nodes = { ui.glyph({ name = look[1], color = look[2] }) }
    if SHOW_LABEL and view.key ~= "idle" then
        nodes[#nodes + 1] = ui.label({ text = noctalia.tr("label." .. view.key), color = look[2] })
    end
    local container = barWidget.isVertical() and ui.column or ui.row
    barWidget.render(container({ gap = 4, align = "center" }, nodes))

    local rows = { { "Hex", noctalia.tr("state." .. view.key) } }
    if view.model then rows[#rows + 1] = { noctalia.tr("tooltip.model"), view.model } end
    if view.meeting then rows[#rows + 1] = { noctalia.tr("tooltip.meeting"), view.meeting } end
    if view.error then rows[#rows + 1] = { noctalia.tr("tooltip.error"), view.error } end
    if view.update then rows[#rows + 1] = { "", noctalia.tr("tooltip.update") } end
    rows[#rows + 1] = { "", noctalia.tr("tooltip.actions") }
    barWidget.setTooltip(rows)
end

noctalia.state.watch("status", render)
render()
