-- Fluent Bit Lua script to determine a low-cardinality, meaningful service.name
-- from systemd journal fields, prioritizing semantic relevance while avoiding
-- high-cardinality noise (e.g., auto-generated .mount units with hashes).

-- Helper function: returns true if the unit name represents a stable, meaningful unit type
-- We allow only unit types that are typically human-defined and have low cardinality.
local function is_meaningful_unit(unit_name)
    if unit_name == nil then
        return false
    end
    -- Accept only well-known, low-cardinality unit types
    return unit_name:match("%.service$") or
        unit_name:match("%.timer$")  or
        unit_name:match("%.socket$") or
        unit_name:match("%.target$") or
        unit_name:match("%.slice$")
end

-- Main filter function called by Fluent Bit
-- Arguments: tag (string), timestamp (number), record (table)
-- Returns: code (1 = keep record), modified timestamp, modified record
function set_service_name(tag, timestamp, record)
    local service_name = nil

    -- 1. Prefer UNIT= (introduced in systemd v251) — but only if it's a meaningful unit
    -- UNIT= expresses the logical context (e.g., which service/timer is being logged about)
    if record["UNIT"] ~= nil and is_meaningful_unit(record["UNIT"]) then
        service_name = record["UNIT"]
    -- 2. Fall back to _SYSTEMD_UNIT — but exclude transient scopes like init.scope
    elseif record["_SYSTEMD_UNIT"] ~= nil and not record["_SYSTEMD_UNIT"]:match("%.scope$") then
        service_name = record["_SYSTEMD_UNIT"]
    -- 3. Use SYSLOG_IDENTIFIER if available (often set by apps via syslog/openlog)
    elseif record["SYSLOG_IDENTIFIER"] ~= nil then
        service_name = record["SYSLOG_IDENTIFIER"]
    -- 4. Last resort: process command name
    elseif record["_COMM"] ~= nil then
        service_name = record["_COMM"]
    elseif record["process.comm"] ~= nil then
        service_name = record["process.comm"]
    else
        service_name = "unknown"
    end

    -- Optional: strip ".service" suffix for cleaner names (e.g., "nginx" instead of "nginx.service")
    -- Uncomment the line below if desired:
    -- service_name = service_name:gsub("%.service$", "")

    -- Set the standardized field used by observability backends
    record["service.name"] = service_name

    return 1, timestamp, record
end
