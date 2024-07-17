local id3 = {}

local function textFrame(name)
    return function(reader, info, frameSize)
        local encoding = reader.readByte()
        info[name] = reader.readStr(frameSize - 1)
    end
end

-- only decode these ID3v2 frames
local frameDecoders = {
    COMM = function(reader, info, frameSize)
        local encoding = reader.readByte()
        local language = reader.readStr(3)
        info.comment = reader.readStr(frameSize - 4)
    end,
    TALB = textFrame 'album',
    TBPM = textFrame 'bpm',
    TENC = textFrame 'encoder',
    TLEN = textFrame 'length',
    TIT2 = textFrame 'title',
    TPE1 = textFrame 'artist',
    TRCK = textFrame 'track',
    TYER = textFrame 'year',
    APIC = function(reader, info, frameSize)
        local encoding = reader.readByte()
        local mimeType = reader.readStr(reader.readStr():find("\0"))
        local pictureType = reader.readByte()
        local description = reader.readStr(reader.readStr():find("\0"))
        local imageData = reader.readStr(frameSize - (1 + #mimeType + 1 + 1 + #description + 1))
        info.coverArt = {
            mimeType = mimeType,
            pictureType = pictureType,
            description = description,
            imageData = imageData,
        }
    end,
}

local function unpad(str)
    return (str:gsub('%z*$', '')) -- removing null padding
end

local function isbitset(x, p)
    local b = 2 ^ (p - 1)
    return x % (b + b) >= b
end

function id3.readtags(filename)
    local file = playdate.file.open(filename, playdate.file.kFileRead)
    if not file then
        return nil, "Cannot open file"
    end

    local position = file:tell()

    local function decodeID3v2(reader)
        local info = {}
        local rb = reader.readByte
        local version = reader.readInt(2)
        local flags = rb()
        local size = reader.readInt(4, 128)

        if isbitset(flags, 7) then
            local mult = version >= 0x0400 and 128 or 256
            local extendedSize = reader.readInt(4, mult)
            local extendedFlags = reader.readInt(2)
            local padding = reader.readInt(4)
            reader.skip(extendedSize - 10)
        end
        while reader.position() < size + 10 do
            local frameID = reader.readStr(4)
            local frameSize = reader.readInt(4)
            local frameFlags = reader.readInt(2)
            if frameDecoders[frameID] then
                frameDecoders[frameID](reader, info, frameSize)
            else
                reader.skip(frameSize)
            end
        end
        file:seek(position)
        return info
    end

    local function decodeID3v1(reader)
        local info = {}
        info.title = unpad(reader.readStr(30))
        info.artist = unpad(reader.readStr(30))
        info.album = unpad(reader.readStr(30))
        info.year = unpad(reader.readStr(4))
        info.comment = unpad(reader.readStr(28))
        local zero = reader.readByte()
        local track = reader.readByte()
        local genre = reader.readByte()
        if zero == 0 then
            info.track = track
            info.genre = genre
        else
            info.comment = unpad(info.comment .. string.char(zero, track, genre))
        end

        file:seek(-128)
        local hdr = reader.readStr(4)
        if hdr == "TAG+" then
            info.title = unpad(info.title .. reader.readStr(60))
            info.artist = unpad(info.artist .. reader.readStr(60))
            info.album = unpad(info.album .. reader.readStr(60))
            -- some other tags omitted
        end

        file:seek(position)
        return info
    end

    local function readByte()
        local byte = assert(file:read(1), 'Could not read byte.')
        return string.byte(byte)
    end

    local reader = {
        readStr = function(len)
            local str = assert(file:read(len), 'Could not read ' .. len .. '-byte string.')
            return unpad(str)
        end,
        readByte = readByte,
        readInt = function(size, mult)
            mult = mult or 256
            local n = readByte()
            for i = 2, size do
                n = n * mult + readByte()
            end
            return n
        end,
        position = function() return file:tell() end,
        skip = function(offset) file:seek(offset) end
    }

    -- try ID3v2
    file:seek(0)
    local header = file:read(3)
    if header == "ID3" then
        return decodeID3v2(reader)
    end

    -- try ID3v1
    file:seek(-128)
    header = file:read(3)
    if header == "TAG" then
        return decodeID3v1(reader)
    end

    return nil
end

return id3
