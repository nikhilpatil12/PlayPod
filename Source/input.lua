function pd.AButtonUp()
    if screen == "main_menu" then
        screen = "player"
    end
end

function pd.BButtonUp()
    if screen == "player" then
        screen = "main_menu"
    end
end
