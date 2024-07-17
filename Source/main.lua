import "utils"
import "player"
import "input"
local ID3 = import 'id3'

local ticksPerRevolution = 3
import "CoreLibs/crank"

local function displayMetadata(filename)
    local metadata, err = ID3.readtags(filename)
    if not metadata then
        gfx.drawText("Error: " .. err, 10, 10)
        return
    end
    print(metadata.title)
    gfx.drawText("Title: " .. metadata.title, 10, 110)
    gfx.drawText("Artist: " .. metadata.artist, 10, 130)
    gfx.drawText("Album: " .. metadata.album, 10, 150)
    gfx.drawText("Year: " .. metadata.year, 10, 170)
    gfx.drawText("Comment: " .. metadata.comment, 10, 190)
    -- gfx.drawText("Genre: " .. metadata.genre, 10, 210)
end


local fontbig = gfx.font.new('images/font/Chicago-20')
local fontsmall = gfx.font.new('images/font/Chicago-15')
screen = "main_menu"

function pd.update()
    local change = playdate.getCrankTicks(ticksPerRevolution)
    -- print(change)

    --Main Menu
    if screen == "main_menu" then
        -- Background in white
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, 200, 240)

        --used for centering
        -- gfx.setColor(gfx.kColorBlack)
        -- gfx.drawLine(200, 0, 200, 240)

        -- Status bar in black

        gfx.setPattern({ 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 })
        -- gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, 400, 30)

        -- Playpod statusbar
        gfx.setColor(gfx.kColorBlack)
        -- gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.setFont(fontbig)
        gfx.drawText("playPod", 164, 3)

        --battery text
        gfx.setFont(fontsmall)
        local battery = math.floor(playdate.getBatteryPercentage())
        gfx.drawText(battery, 325, 6)
        -- gfx.drawText("%", 358, 3)

        --battery graphic
        gfx.drawRect(360, 7, 30, 14)
        gfx.drawRect(390, 12, 2, 4)
        gfx.fillRect(360, 7, battery / 3.3, 14)

        gfx.setColor(gfx.kColorBlack)
        -- local font = playdate.graphics.getSystemFont()

        playdate.graphics.setFont(fontbig)
        -- menuItems={}

        displayMetadata("sounds/Escape (The Pina Colada Song).mp3")
        gfx.drawText("Hello", 10, 40)
        gfx.drawText("World2", 10, 60)



        --Player Screen
    elseif screen == "player" then
        -- Background in black
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, 400, 240)
    end
end
