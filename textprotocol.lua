local textprotocol = {}

local error = error
local assert = assert
local pairs = pairs
local type = type
local table = table
local insert = table.insert
local tostring = tostring
local tonumber = tonumber
local string = string
local format = string.format
local sub = string.sub
local find = string.find

---@alias textprotocol.types string | number | boolean | table | nil

---comment
---@return string[]
local function buffer_new()
    return {}
end

---comment
---@param sb string[]
---@param content string | string[]
local function buffer_append(sb, content)
    local tp = type(content)
    if tp == 'string' then
        insert(sb, content)
    else
        for i = 1, #content do
            insert(sb, content[i])
        end
    end
end

---comment
---@param sb string[]
---@return string
local function buffer_tostring(sb)
    return table.concat(sb)
end

---comment
---@param value textprotocol.types
---@param sb string[]
local function value2string(value, sb)
    local tp = type(value)
    if tp == 'string' then
        buffer_append(sb, format("S[%d]%s", #value, value))
    elseif tp == 'number' then
        value = tostring(value)
        buffer_append(sb, format("N[%d]%s", #value, value))
    elseif tp == 'boolean' then
		if value then
			buffer_append(sb, "t")
		else
			buffer_append(sb, "f")
		end
    elseif tp == 'nil' then
		buffer_append(sb, "n")
    elseif tp == 'table' then
        local subsb = buffer_new()
        local count = 0
        for k, v in pairs(value) do
            value2string(k, subsb)
            value2string(v, subsb)
            count = count + 1
        end
        buffer_append(sb, format("T[%d]", count))
        buffer_append(sb, subsb)
    else
        error("unsupported type:" .. tp)
    end
end

---comment
---@param str string
---@param idx integer @ begin index of string
---@return textprotocol.types @ result
---@return integer @ offset
local function string2value(str, idx)
    local tp = sub(str, idx, idx)
	if tp == "t" then
		return true, idx + 1
	elseif tp == "f" then
		return false, idx + 1
	elseif tp == "n" then
		return nil, idx + 1
    elseif tp == "S" or tp == "N" then
		local lenend = find(str, "]", idx + 1)
		local len = tonumber(sub(str, idx + 2, lenend - 1))

        ---@type string | number
        local value = sub(str, lenend + 1, lenend + len)
        if tp == "N" then
            local n = tonumber(value)
            if not n then
                error(format("parse error: tonumber fail: (%d), (%s)", idx, value))
            end
            value = n
        end
        return value, lenend + len + 1
    elseif tp == "T" then
		local lenend = find(str, "]", idx + 1)
		local len = tonumber(sub(str, idx + 2, lenend - 1))

        local value = {}
        local newidx = lenend + 1
        local k, v
		local array = true
        for i = 1, len do
            k, newidx = string2value(str, newidx)
            v, newidx = string2value(str, newidx)
			if array and k == i then
				insert(value, v)
			else
                if not k then
                    error(format("parse error: key of table cannot be nil: (%d)", idx))
                end
				value[k] = v
				array = false
			end
        end
        return value, newidx
    else
        error(format("parse error type(%s)", tp))
    end
end

---comment
---@param tbl table
---@return string
function textprotocol.table2string(tbl)
    local buffer = buffer_new()
    value2string(tbl, buffer)
    return buffer_tostring(buffer)
end

---comment
---@param value textprotocol.types
---@return string
function textprotocol.value2string(value)
    local buffer = buffer_new()
    value2string(value, buffer)
    return buffer_tostring(buffer)
end

---comment
---@param str string
---@param idx? integer @ begin index of string
---@return table?
---@return integer @ offset
function textprotocol.string2table(str, idx)
	if str == nil then
		return nil, 0
	end
    assert(type(str) == 'string')
	if #str == 0 then
		return nil, 0
	end
	local v, offset = string2value(str, idx or 1)
    if type(v) == 'table' then
        return v, offset
    else
        return nil, offset
    end
end

---comment
---@param str string
---@param idx? integer @ begin index of string
---@return textprotocol.types @ result
---@return integer @ offset
function textprotocol.string2value(str, idx)
	if str == nil then
		return nil, 0
	end
    assert(type(str) == 'string')
	if #str == 0 then
		return nil, 0
	end
	return string2value(str, idx or 1)
end

-- local str = textprotocol.value2string({
--     a = {
--         b = 'a.b',
--         123,
--     }
-- })
-- 
-- print(str)
-- local dump = require 'dump'
-- dump.toprint(textprotocol.string2value(str))

return textprotocol