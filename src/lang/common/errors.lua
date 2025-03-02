local Strings = require("src.lang.common.utils.strings")
local Errors, Error = {}, {}

function Error:new(start, _end, error, details)
    return setmetatable({
            pos_start = start, pos_end = _end,
            error_name = error, details = details
        }, {
            __tostring = function(t)
                local result = Strings.colored("red", string.format("%s: %s\n", t.error_name, t.details))
                if t.pos_start then
                    result = result..string.format("    --> File %s, line: %d\n",
                        t.pos_start.fn or "unknown",
                        (t.pos_start.ln or 0) + 1)
                    if t.pos_start.ft then
                        result = result..Strings.add_arrows(t.pos_start.ft, t.pos_start, t.pos_end)
                    end
                end
                return result
            end
        }
    )
end
local IllegalCharError = setmetatable({}, { __index = Error })
function IllegalCharError:new(start, _end, details)
    return Error:new(start, _end, "Illegal Character", details)
end
Errors.IllegalCharError = IllegalCharError

local ExpectedCharError = setmetatable({}, { __index = Error })
function ExpectedCharError:new(start, _end, details)
    return Error:new(start, _end, "Expected Char", details)
end
Errors.ExpectedCharError = ExpectedCharError

local InvalidSyntaxError = setmetatable({}, { __index = Error })
function InvalidSyntaxError:new(start, _end, details) details = details or ""
    return Error:new(start, _end, "Invalid Syntax", details)
end
Errors.InvalidSyntaxError = InvalidSyntaxError

local RTError = setmetatable({}, { __index = Error })
function RTError:new(start, _end, details, context)
    local instance = Error:new(start, _end, "Runtime Error", details)
    instance.context = context
    instance.generate_traceback = function(self)
        if not self.context then
            return "Traceback: (no context available)\n"
        end
        local result = Strings.colored("red", "Traceback (most recent call last):\n")
        local pos, ctx = self.pos_start, self.context
        while ctx do
            result = string.format("    --> File %s, line %d, in: %s\n", pos.fn, pos.ln + 1, ctx.display_name)..result
            pos = ctx.parent_entry_pos; ctx = ctx.parent
        end
        return result
    end
    setmetatable(instance, {
        __tostring = function(t)
            local result = t:generate_traceback()
            result = result..Strings.colored("red", string.format("%s: %s\n", t.error_name, t.details))
            result = result..Strings.add_arrows(t.pos_start.ftx, t.pos_start, t.pos_end)
            return result
        end
    })
    return instance
end
Errors.RTError = RTError

return setmetatable(Errors, {
    __call = function(_, subclass_name, start, _end, details, context)
        print("Calling Errors with subclass_name:", tostring(subclass_name))
        local subclass = Errors[tostring(subclass_name)]
        if subclass then return subclass:new(start, _end, details, context)
        else error("Invalid error subclass: "..tostring(subclass_name)) end
    end
})