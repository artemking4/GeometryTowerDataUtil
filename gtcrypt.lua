local fs = require "fs"
local lyaml = require "lyaml"
local textProtocol = require "./textprotocol"

local supernovaCrypto = {
    randmap = {
        4001, 4003, 4007, 4013, 4019, 4021, 4027, 4049, 4051, 4057, 4073, 4079, 4091, 4093, 4099,
        4111, 4127, 4129, 4133, 4139, 4153, 4157, 4159, 4177, 4201, 4211, 4217, 4219, 4229, 4231,
        4241, 4243, 4253, 4259, 4261, 4271, 4273, 4283, 4289, 4297, 4327, 4337, 4339, 4349, 4357,
        4363, 4373, 4391, 4397, 4409, 4421, 4423, 4441, 4447, 4451, 4457, 4463, 4481, 4483, 4493,
        4507, 4513, 4517, 4519, 4523, 4547, 4549, 4561, 4567, 4583, 4591, 4597, 4603, 4621, 4637,
        4639, 4643, 4649, 4651, 4657, 4663, 4673, 4679, 4691, 4703, 4721, 4723, 4729, 4733, 4751,
        4759, 4783, 4787, 4789, 4793, 4799, 4801, 4813, 4817, 4831, 4861, 4871, 4877, 4889, 4903,
        4909, 4919, 4931, 4933, 4937, 4943, 4951, 4957, 4967, 4969, 4973, 4987, 4993, 4999, 5003
    }
}

-- Supernova.Security.CryptoSimple$$GetResetCipherRemain
function supernovaCrypto.getResetCipherRemain(cipher)
    cipher = bit.band(cipher, 0xFF) + 1

    local idx = cipher - math.floor(cipher / 120) * 120
    local v = assert(supernovaCrypto.randmap[idx + 1]) + bit.rshift(bit.band(bit.band(cipher, 0xFFFF) ^ 2, 0xFFFF), 1)
    return (v - bit.band(v + bit.rshift(bit.rshift(v, 0x1f), 0x16), 0xfffffc00)) + 0x400
end

-- Supernova.Security.CryptoSimple$$Decrypt
function supernovaCrypto.decrypt(data)
    local key = bit.band(#data, 0xFF)
    
    local remain = supernovaCrypto.getResetCipherRemain(#data)
    for i = 1, #data do
        data[i] = bit.bxor(data[i], key)

        remain = remain - 1
        key = bit.band(key + data[i], 0xFF)
        if remain <= 0 then
            key = bit.band(data[i] + bit.band(key, 0xFF), 0xFF)
            remain = supernovaCrypto.getResetCipherRemain(key)
        end
    end

    return data
end

-- Supernova.Security.CryptoSimple$$Encrypt
function supernovaCrypto.encrypt(data)
    local key = bit.band(#data, 0xFF)

    local remain = supernovaCrypto.getResetCipherRemain(#data)
    for i = 1, #data do
        local orgbyte = data[i]
        data[i] = bit.bxor(orgbyte, key)
        key = bit.band(key + orgbyte, 0xFF)
        
        remain = remain - 1
        if remain <= 0 then
            key = bit.band(orgbyte + bit.band(key, 0xFF), 0xFF)
            remain = supernovaCrypto.getResetCipherRemain(key)
        end
    end

    return data
end

local slice = 4096
local function s2b(str)
    local t = { }

    local function helper(...)
        for i = 1, select('#', ...) do
            table.insert(t, (select(i, ...)))
        end
    end

    for i = 1, #str, slice do
        helper(str:byte(i, i + slice - 1))
    end

    return t
end

local function b2s(bytes)
    local t = { }
    for i = 1, #bytes, slice do
        table.insert(t, string.char(unpack(bytes, i, math.min(i + slice - 1, #bytes))))
    end

    return table.concat(t)
end

local action = assert(args[2], "no action")

if action == "decrypt" then
    local file = assert(args[3])
    local outfile = assert(args[4])
    local data = s2b(fs.readFileSync(file))

    data = supernovaCrypto.decrypt(data)

    local out = b2s(data)
    
    fs.writeFileSync(outfile, out)
elseif action == "encrypt" then
    local file = assert(args[3])
    local outfile = assert(args[4])
    local data = s2b(fs.readFileSync(file))

    data = supernovaCrypto.encrypt(data)

    local out = b2s(data)
    
    fs.writeFileSync(outfile, out)
elseif action == "saveDecode" then
    local file = assert(args[3])
    local outfile = assert(args[4])
    local data = s2b(fs.readFileSync(file))

    data = supernovaCrypto.decrypt(data)

    fs.writeFileSync(outfile, 
        lyaml.dump({ 
            (assert(textProtocol.string2value(b2s(data)))) 
        })
    )
elseif action == "saveEncode" then
    local file = assert(args[3])
    local outfile = assert(args[4])

    local data = supernovaCrypto.encrypt(s2b(
            assert(textProtocol.value2string(
                (assert(lyaml.load(assert(fs.readFileSync(file)))))
            ))
        ))

    fs.writeFileSync(outfile, b2s(data))
else
    error "bad action"
end