--- Tiny test harness: register with `test`, check with `eq`/`near`/`ok`/`raises`.

local lib = { cases = {} }

function lib.test(name, fn)
    lib.cases[#lib.cases + 1] = { name = name, fn = fn }
end

local function fail(message, level)
    error(message, (level or 1) + 2)
end

function lib.ok(value, message)
    if not value then fail(message or "expected truthy value") end
end

function lib.eq(actual, expected, message)
    if actual ~= expected then
        fail(("%sexpected %s, got %s"):format(message and message .. ": " or "", tostring(expected), tostring(actual)))
    end
end

function lib.near(actual, expected, message, epsilon)
    if math.abs(actual - expected) > (epsilon or 1e-9) then
        fail(("%sexpected ~%s, got %s"):format(message and message .. ": " or "", tostring(expected), tostring(actual)))
    end
end

function lib.raises(fn, pattern)
    local ok, err = pcall(fn)
    if ok then fail("expected an error") end
    if pattern and not tostring(err):find(pattern) then
        fail(("error %q does not match %q"):format(tostring(err), pattern))
    end
end

--- Runs all registered cases; returns the number of failures.
function lib.run()
    local failures = 0
    for _, case in ipairs(lib.cases) do
        local ok, err = pcall(case.fn)
        if not ok then
            failures = failures + 1
            print(("FAIL  %s\n      %s"):format(case.name, err))
        end
    end
    print(("%d passed, %d failed"):format(#lib.cases - failures, failures))
    return failures
end

return lib
