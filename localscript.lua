-- LOCAL SCRIPT - Wattpad Clone UI v4.1 TIEMPO REAL
-- Colocar en StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Client] Iniciando Wattpad UI v4.1 (Tiempo Real)...")

-- Esperar RemoteEvents
local success, RemoteFolder = pcall(function()
    return ReplicatedStorage:WaitForChild("WattpadRemotes", 10)
end)

if not success or not RemoteFolder then
    warn("[Client] ERROR: No se encontró WattpadRemotes. Verifica que el ServerScript esté corriendo.")
    return
end

local PublishStoryEvent = RemoteFolder:WaitForChild("PublishStory")
local UpdateStoryEvent = RemoteFolder:WaitForChild("UpdateStory")
local GetAllStoriesFunction = RemoteFolder:WaitForChild("GetAllStories")
local GetStoriesByCategoryFunction = RemoteFolder:WaitForChild("GetStoriesByCategory")
local GetUserStoriesFunction = RemoteFolder:WaitForChild("GetUserStories")
local SearchStoriesFunction = RemoteFolder:WaitForChild("SearchStories")
local GetStoryByIdFunction = RemoteFolder:WaitForChild("GetStoryById")

local GetAuthorProfileFunction = RemoteFolder:WaitForChild("GetAuthorProfile")
local FollowAuthorEvent = RemoteFolder:WaitForChild("FollowAuthor")
local UnfollowAuthorEvent = RemoteFolder:WaitForChild("UnfollowAuthor")
local SearchAuthorsFunction = RemoteFolder:WaitForChild("SearchAuthors")
local GetAllAuthorsFunction = RemoteFolder:WaitForChild("GetAllAuthors")

-- ⭐ NUEVOS EVENTOS DE TIEMPO REAL
local StoryUpdatedEvent = RemoteFolder:WaitForChild("StoryUpdated")
local AuthorUpdatedEvent = RemoteFolder:WaitForChild("AuthorUpdated")
local IncrementViewEvent = RemoteFolder:WaitForChild("IncrementView")

print("[Client] Todos los RemoteEvents cargados")

-- Categorías
local Categories = {
"Romance", "Fantasía", "Ciencia Ficción", "Misterio",
"Terror", "Aventura", "Drama", "Comedia",
"Fanfic", "Poesía", "Acción", "Thriller"
}

-- COLORES
local Colors = {
Primary = Color3.fromRGB(0, 102, 255),
Secondary = Color3.fromRGB(76, 151, 255),
Background = Color3.fromRGB(25, 27, 29),
CardBg = Color3.fromRGB(35, 38, 42),
White = Color3.fromRGB(255, 255, 255),
Gray = Color3.fromRGB(189, 190, 190),
DarkGray = Color3.fromRGB(117, 117, 117),
Accent = Color3.fromRGB(0, 102, 255),
Success = Color3.fromRGB(2, 183, 87),
Warning = Color3.fromRGB(255, 168, 0),
LightBg = Color3.fromRGB(57, 59, 61)
}

-- Variables de estado
local currentScreen = "home"
local currentStory = nil
local editingStoryId = nil
local currentAuthorProfile = nil
local currentSearchTab = "historias"

-- ⭐ Cache local de historias (se actualiza en tiempo real)
local LocalStoriesCache = {}

local formData = {
title = "",
synopsis = "",
category = "Romance",
status = "En progreso",
characters = {},
content = ""
}

-- ============= FUNCIONES UTILIDAD =============

local function Round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function Stroke(parent, color, thickness)
    local str = Instance.new("UIStroke")
    str.Color = color or Colors.DarkGray
    str.Thickness = thickness or 1
    str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    str.Parent = parent
    return str
end

local function Frame(parent, size, pos, bg, radius)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = bg or Colors.Background
    f.BorderSizePixel = 0
    f.Parent = parent
    if radius then Round(f, radius) end
    return f
end

local function Label(parent, text, size, pos, color, fontSize)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Colors.White
    l.Font = Enum.Font.GothamBold
    l.TextSize = fontSize or 16
    l.TextWrapped = true
    l.TextScaled = false
    l.Parent = parent
    return l
end

local function Btn(parent, text, size, pos, bg, textColor, onClick)
    local btn = Frame(parent, size, pos, bg, 8)
    local lbl = Label(btn, text, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), textColor, 16)
    lbl.Font = Enum.Font.GothamBold

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Text = ""
    b.Parent = btn

    if onClick then
        b.MouseButton1Click:Connect(onClick)
    end

    b.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        BackgroundColor3 = Color3.fromRGB(
        math.min(bg.R * 255 + 20, 255),
        math.min(bg.G * 255 + 20, 255),
        math.min(bg.B * 255 + 20, 255)
        )
        }):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = bg}):Play()
    end)

    return btn, b
end

local function Input(parent, placeholder, size, pos, multiline)
    local f = Frame(parent, size, pos, Colors.CardBg, 8)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 1, -24)
    box.Position = UDim2.new(0, 12, 0, 12)
    box.BackgroundTransparency = 1
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Colors.DarkGray
    box.Text = ""
    box.TextColor3 = Colors.White
    box.Font = Enum.Font.Gotham
    box.TextSize = 15
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = f

    if multiline then
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.MultiLine = true
        box.TextWrapped = true
    else
        box.TextYAlignment = Enum.TextYAlignment.Center
    end

    return box
end

local function CreateLoadingSpinner(parent)
    local spinnerContainer = Frame(parent, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0, 0.5), 0)
    spinnerContainer.BackgroundTransparency = 0.3
    spinnerContainer.ZIndex = 100
    spinnerContainer.Visible = false
    spinnerContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

    local spinnerFrame = Frame(spinnerContainer, UDim2.new(0, 60, 0, 60), UDim2.new(0.5, -30, 0.5, -30), Colors.Primary, 30)
    spinnerFrame.ZIndex = 101

    local innerCircle = Frame(spinnerFrame, UDim2.new(0.55, 0, 0.55, 0), UDim2.new(0.225, 0, 0.225, 0), Colors.Background, 30)
    innerCircle.ZIndex = 102

    local dot = Frame(spinnerFrame, UDim2.new(0, 8, 0, 8), UDim2.new(0.5, -4, 0, 2), Colors.White, 4)
    dot.ZIndex = 103

    local rotating = false
    local rotationCoroutine = nil

    local function startRotation()
        rotating = true
        rotationCoroutine = coroutine.create(function()
            while rotating do
                for rot = 0, 360, 8 do
                    if not rotating then break end
                    spinnerFrame.Rotation = rot
                    task.wait(0.02)
                end
            end
            spinnerFrame.Rotation = 0
        end)
        coroutine.resume(rotationCoroutine)
    end

    local function stopRotation()
        rotating = false
        if rotationCoroutine then
            coroutine.close(rotationCoroutine)
            rotationCoroutine = nil
        end
        spinnerFrame.Rotation = 0
    end

    return spinnerContainer, startRotation, stopRotation
end

-- ============= CREAR SCREENGUI =============

local gui = Instance.new("ScreenGui")
gui.Name = "WattpadUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Frame(gui, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)

-- ============= NAVBAR =============

local navbar = Frame(main, UDim2.new(1, 0, 0, 67), UDim2.new(0, 0, 1, -67), Colors.CardBg, 0)
local navLine = Frame(navbar, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), Colors.Primary, 0)

local navBtns = {}

local function NavBtn(icon, text, xPos, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = navbar

    local iconL = Label(btn, icon, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 10), Colors.Gray, 22)
    local textL = Label(btn, text, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 40), Colors.Gray, 11)
    textL.Font = Enum.Font.GothamMedium

    btn.MouseButton1Click:Connect(function()
        for _, n in pairs(navBtns) do
            n.icon.TextColor3 = Colors.Gray
            n.text.TextColor3 = Colors.Gray
        end
        iconL.TextColor3 = Colors.Primary
        textL.TextColor3 = Colors.Primary
        if onClick then onClick() end
    end)

    navBtns[text] = {btn = btn, icon = iconL, text = textL}
    return btn
end

local GoHome, GoSearch, GoCreate, GoProfile, LoadStories, GoDetails, CreateCard

NavBtn("🏠", "Inicio", 0, function() GoHome() end)
    NavBtn("🔍", "Buscar", 0.25, function() GoSearch() end)
        NavBtn("✏️", "Publicar", 0.5, function() GoCreate() end)
            NavBtn("👤", "Perfil", 0.75, function() GoProfile() end)

                -- ============= ÁREA DE CONTENIDO =============

                local content = Frame(main, UDim2.new(1, 0, 1, -77), UDim2.new(0, 0, 0, 35), Colors.Background, 0)
                content.BackgroundTransparency = 1
                content.ClipsDescendants = true

                local screens = {}

                -- ==================== INICIO ====================

                local homeScr = Instance.new("ScrollingFrame")
                homeScr.Size = UDim2.new(1, -20, 1, -20)
                homeScr.Position = UDim2.new(0, 10, 0, 5)
                homeScr.BackgroundTransparency = 1
                homeScr.BorderSizePixel = 0
                homeScr.ScrollBarThickness = 4
                homeScr.ScrollBarImageColor3 = Colors.Primary
                homeScr.Visible = true
                homeScr.Parent = content
                screens.home = homeScr

                local homeList = Instance.new("UIListLayout")
                homeList.Padding = UDim.new(0, 16)
                homeList.SortOrder = Enum.SortOrder.LayoutOrder
                homeList.Parent = homeScr

                homeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    homeScr.CanvasSize = UDim2.new(0, 0, 0, homeList.AbsoluteContentSize.Y + 40)
                end)

                local appTitle = Label(homeScr, "Wemix", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), Colors.Primary, 28)
                appTitle.LayoutOrder = 1
                appTitle.TextXAlignment = Enum.TextXAlignment.Center
                appTitle.Font = Enum.Font.GothamBold

                local homeTitle = Label(homeScr, "Historias", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                homeTitle.LayoutOrder = 2
                homeTitle.TextXAlignment = Enum.TextXAlignment.Left

                local carousels = {}

                for i, cat in ipairs(Categories) do
                    local container = Frame(homeScr, UDim2.new(1, 0, 0, 230), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                    container.LayoutOrder = i + 2
                    container.BackgroundTransparency = 1

                    local catTitle = Label(container, cat, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Colors.Primary, 17)
                    catTitle.TextXAlignment = Enum.TextXAlignment.Left
                    catTitle.Font = Enum.Font.GothamBold

                    local scroll = Instance.new("ScrollingFrame")
                    scroll.Size = UDim2.new(1, 0, 0, 200)
                    scroll.Position = UDim2.new(0, 0, 0, 28)
                    scroll.BackgroundTransparency = 1
                    scroll.BorderSizePixel = 0
                    scroll.ScrollBarThickness = 0
                    scroll.ScrollingDirection = Enum.ScrollingDirection.X
                    scroll.CanvasSize = UDim2.new(0, 0, 0, 200)
                    scroll.Parent = container

                    local layout = Instance.new("UIListLayout")
                    layout.FillDirection = Enum.FillDirection.Horizontal
                    layout.Padding = UDim.new(0, 12)
                    layout.Parent = scroll

                    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        scroll.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 12, 0, 0)
                    end)

                    carousels[cat] = scroll
                end

                -- [El resto del código continúa igual hasta las funciones de navegación...]
                -- Por brevedad, continuaré con las partes críticas corregidas

                -- ==================== BUSCAR ====================

                local searchScr = Frame(content, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                searchScr.Visible = false
                searchScr.BackgroundTransparency = 1
                screens.search = searchScr

                local searchBarContainer = Frame(searchScr, UDim2.new(1, -30, 0, 45), UDim2.new(0, 15, 0, 25), Colors.Background, 0)
                searchBarContainer.BackgroundTransparency = 1

                local searchBarBg = Frame(searchBarContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.LightBg, 8)
                Stroke(searchBarBg, Colors.Primary, 2)

                local searchIcon = Label(searchBarBg, "🔍", UDim2.new(0, 30, 1, 0), UDim2.new(0, 8, 0, 0), Colors.Gray, 16)

                local searchBox = Instance.new("TextBox")
                searchBox.Size = UDim2.new(1, -50, 1, 0)
                searchBox.Position = UDim2.new(0, 40, 0, 0)
                searchBox.BackgroundTransparency = 1
                searchBox.PlaceholderText = "Buscar..."
                searchBox.PlaceholderColor3 = Colors.DarkGray
                searchBox.Text = ""
                searchBox.TextColor3 = Colors.White
                searchBox.Font = Enum.Font.Gotham
                searchBox.TextSize = 15
                searchBox.TextXAlignment = Enum.TextXAlignment.Left
                searchBox.TextYAlignment = Enum.TextYAlignment.Center
                searchBox.ClearTextOnFocus = false
                searchBox.Parent = searchBarBg

                local searchSpinner, startSearchSpinner, stopSearchSpinner = CreateLoadingSpinner(searchScr)

                -- Pills y tabs similares al código original...
                local catPillsFrame = Frame(searchScr, UDim2.new(1, -20, 0, 45), UDim2.new(0, 10, 0, 78), Colors.Background, 0)
                catPillsFrame.BackgroundTransparency = 1

                local catPillsScroll = Instance.new("ScrollingFrame")
                catPillsScroll.Size = UDim2.new(1, 0, 1, 0)
                catPillsScroll.Position = UDim2.new(0, 0, 0, 0)
                catPillsScroll.BackgroundTransparency = 1
                catPillsScroll.BorderSizePixel = 0
                catPillsScroll.ScrollBarThickness = 0
                catPillsScroll.ScrollingDirection = Enum.ScrollingDirection.X
                catPillsScroll.Parent = catPillsFrame

                local catPillsLayout = Instance.new("UIListLayout")
                catPillsLayout.FillDirection = Enum.FillDirection.Horizontal
                catPillsLayout.Padding = UDim.new(0, 8)
                catPillsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                catPillsLayout.Parent = catPillsScroll

                catPillsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    catPillsScroll.CanvasSize = UDim2.new(0, catPillsLayout.AbsoluteContentSize.X + 10, 0, 0)
                end)

                local FilterSearchResults
                local selectedCatPill = nil

                local function CreateCatPill(cat)
                    local pill = Frame(catPillsScroll, UDim2.new(0, 0, 0, 32), UDim2.new(0,0,0,0), Colors.CardBg, 16)
                    pill.AutomaticSize = Enum.AutomaticSize.X
                    Stroke(pill, Colors.Primary, 1)

                    local pillPad = Instance.new("UIPadding")
                    pillPad.PaddingLeft = UDim.new(0, 16)
                    pillPad.PaddingRight = UDim.new(0, 16)
                    pillPad.PaddingTop = UDim.new(0, 4)
                    pillPad.PaddingBottom = UDim.new(0, 4)
                    pillPad.Parent = pill

                    local lbl = Label(pill, cat, UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Gray, 13)
                    lbl.AutomaticSize = Enum.AutomaticSize.X
                    lbl.TextWrapped = false
                    lbl.Font = Enum.Font.GothamMedium

                    local clickBtn = Instance.new("TextButton")
                    clickBtn.Size = UDim2.new(1, 0, 1, 0)
                    clickBtn.BackgroundTransparency = 1
                    clickBtn.Text = ""
                    clickBtn.Parent = pill

                    clickBtn.MouseButton1Click:Connect(function()
                        for _, c in ipairs(catPillsScroll:GetChildren()) do
                            if c:IsA("Frame") then
                                c.BackgroundColor3 = Colors.CardBg
                                c.UIStroke.Color = Colors.Primary
                                for _, ch in ipairs(c:GetChildren()) do
                                    if ch:IsA("TextLabel") then ch.TextColor3 = Colors.Gray end
                                end
                            end
                        end
                        pill.BackgroundColor3 = Colors.Primary
                        pill.UIStroke.Color = Colors.Primary
                        lbl.TextColor3 = Colors.White
                        selectedCatPill = cat

                        if FilterSearchResults then FilterSearchResults(cat) end
                    end)

                    return pill
                end

                local todoP = CreateCatPill("De Todo")
                todoP.BackgroundColor3 = Colors.Primary
                todoP.UIStroke.Color = Colors.Primary
                for _, ch in ipairs(todoP:GetChildren()) do
                    if ch:IsA("TextLabel") then ch.TextColor3 = Colors.White end
                end

                for _, cat in ipairs(Categories) do
                    CreateCatPill(cat)
                end

                local searchTabsFrame = Frame(searchScr, UDim2.new(1, -30, 0, 40), UDim2.new(0, 15, 0, 131), Colors.Background, 0)
                searchTabsFrame.BackgroundTransparency = 1

                local tabHistoriasBtn, tabAutoresBtn
                tabHistoriasBtn = Btn(searchTabsFrame, "📚 Historias", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                    currentSearchTab = "historias"
                    tabHistoriasBtn.BackgroundColor3 = Colors.Primary
                    tabAutoresBtn.BackgroundColor3 = Colors.CardBg
                    tabHistoriasBtn.TextLabel.TextColor3 = Colors.White
                    tabAutoresBtn.TextLabel.TextColor3 = Colors.Gray
                    if FilterSearchResults then FilterSearchResults(selectedCatPill) end
                end)

                tabAutoresBtn = Btn(searchTabsFrame, "👥 Autores", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                    currentSearchTab = "autores"
                    tabHistoriasBtn.BackgroundColor3 = Colors.CardBg
                    tabAutoresBtn.BackgroundColor3 = Colors.Primary
                    tabHistoriasBtn.TextLabel.TextColor3 = Colors.Gray
                    tabAutoresBtn.TextLabel.TextColor3 = Colors.White
                    if FilterSearchResults then FilterSearchResults(selectedCatPill) end
                end)

                local resultCountLabel = Label(searchScr, "Resultados", UDim2.new(0, 150, 0, 24), UDim2.new(0, 15, 0, 179), Colors.White, 15)
                resultCountLabel.TextXAlignment = Enum.TextXAlignment.Left
                resultCountLabel.Font = Enum.Font.GothamBold

                local searchScroll = Instance.new("ScrollingFrame")
                searchScroll.Size = UDim2.new(1, -30, 1, -214)
                searchScroll.Position = UDim2.new(0, 15, 0, 209)
                searchScroll.BackgroundTransparency = 1
                searchScroll.BorderSizePixel = 0
                searchScroll.ScrollBarThickness = 4
                searchScroll.ScrollBarImageColor3 = Colors.Primary
                searchScroll.Parent = searchScr

                local searchList = Instance.new("UIListLayout")
                searchList.Padding = UDim.new(0, 10)
                searchList.SortOrder = Enum.SortOrder.LayoutOrder
                searchList.Parent = searchScroll

                searchList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    searchScroll.CanvasSize = UDim2.new(0, 0, 0, searchList.AbsoluteContentSize.Y + 20)
                end)

                -- ==================== CREAR ====================

                local createScr = Frame(content, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                createScr.Visible = false
                createScr.BackgroundTransparency = 1
                screens.create = createScr

                local createTitle = Label(createScr, "Publicar historia", UDim2.new(1, -30, 0, 30), UDim2.new(0, 15, 0, 20), Colors.White, 20)
                createTitle.TextXAlignment = Enum.TextXAlignment.Left

                local createTitleInput = Input(createScr, "Título", UDim2.new(1, -30, 0, 52), UDim2.new(0, 15, 0, 60), false)
                local createSynopsisInput = Input(createScr, "Sinopsis", UDim2.new(1, -30, 0, 90), UDim2.new(0, 15, 0, 120), true)
                local createContentInput = Input(createScr, "Contenido", UDim2.new(1, -30, 0, 180), UDim2.new(0, 15, 0, 220), true)

                local selectedCategory = formData.category
                local categoryBtn = Btn(createScr, "Categoría: " .. selectedCategory, UDim2.new(1, -30, 0, 38), UDim2.new(0, 15, 0, 412), Colors.CardBg, Colors.White, function()
                    local currentIndex = table.find(Categories, selectedCategory) or 1
                    local nextIndex = currentIndex + 1
                    if nextIndex > #Categories then nextIndex = 1 end
                    selectedCategory = Categories[nextIndex]
                    categoryBtn.TextLabel.Text = "Categoría: " .. selectedCategory
                end)

                local publishBtn = Btn(createScr, "Publicar", UDim2.new(1, -30, 0, 42), UDim2.new(0, 15, 0, 458), Colors.Primary, Colors.White, function()
                    local storyData = {
                        title = createTitleInput.Text,
                        synopsis = createSynopsisInput.Text,
                        content = createContentInput.Text,
                        category = selectedCategory,
                        status = "En progreso",
                        characters = {}
                    }

                    if storyData.title == "" then
                        warn("[Client] ⚠️ Debes escribir un título")
                        return
                    end

                    PublishStoryEvent:FireServer(storyData)
                    createTitleInput.Text = ""
                    createSynopsisInput.Text = ""
                    createContentInput.Text = ""
                    GoHome()
                end)

                -- ==================== DETALLES ====================

                local detailsScr = Frame(content, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                detailsScr.Visible = false
                detailsScr.BackgroundTransparency = 1
                screens.details = detailsScr

                local detailsBackBtn = Btn(detailsScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 15, 0, 20), Colors.CardBg, Colors.White, function()
                    GoHome()
                end)

                local detailsTitle = Label(detailsScr, "", UDim2.new(1, -30, 0, 36), UDim2.new(0, 15, 0, 66), Colors.White, 22)
                detailsTitle.TextXAlignment = Enum.TextXAlignment.Left
                local detailsMeta = Label(detailsScr, "", UDim2.new(1, -30, 0, 20), UDim2.new(0, 15, 0, 102), Colors.Gray, 13)
                detailsMeta.TextXAlignment = Enum.TextXAlignment.Left
                local detailsSynopsis = Label(detailsScr, "", UDim2.new(1, -30, 0, 70), UDim2.new(0, 15, 0, 126), Colors.White, 14)
                detailsSynopsis.TextXAlignment = Enum.TextXAlignment.Left
                detailsSynopsis.TextYAlignment = Enum.TextYAlignment.Top
                local detailsContent = Label(detailsScr, "", UDim2.new(1, -30, 1, -240), UDim2.new(0, 15, 0, 204), Colors.Gray, 13)
                detailsContent.TextXAlignment = Enum.TextXAlignment.Left
                detailsContent.TextYAlignment = Enum.TextYAlignment.Top

                -- ==================== PERFIL ====================

                local profileScr = Instance.new("ScrollingFrame")
                profileScr.Size = UDim2.new(1, -30, 1, -20)
                profileScr.Position = UDim2.new(0, 15, 0, 5)
                profileScr.BackgroundTransparency = 1
                profileScr.BorderSizePixel = 0
                profileScr.ScrollBarThickness = 4
                profileScr.ScrollBarImageColor3 = Colors.Primary
                profileScr.Visible = false
                profileScr.Parent = content
                screens.profile = profileScr

                local profileList = Instance.new("UIListLayout")
                profileList.Padding = UDim.new(0, 12)
                profileList.SortOrder = Enum.SortOrder.LayoutOrder
                profileList.Parent = profileScr
                profileList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    profileScr.CanvasSize = UDim2.new(0, 0, 0, profileList.AbsoluteContentSize.Y + 30)
                end)

                local myProfileTitle = Label(profileScr, "Mi perfil", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                myProfileTitle.LayoutOrder = 1
                myProfileTitle.TextXAlignment = Enum.TextXAlignment.Left
                local myProfileName = Label(profileScr, player.DisplayName .. " (@" .. player.Name .. ")", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Colors.Gray, 14)
                myProfileName.LayoutOrder = 2
                myProfileName.TextXAlignment = Enum.TextXAlignment.Left
                local myStoriesTitle = Label(profileScr, "Mis historias", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Colors.White, 16)
                myStoriesTitle.LayoutOrder = 3
                myStoriesTitle.TextXAlignment = Enum.TextXAlignment.Left

                local function ClearMyStories()
                    for _, child in ipairs(profileScr:GetChildren()) do
                        if child:IsA("Frame") and (child.Name == "MyStoryCard") then
                            child:Destroy()
                        end
                    end
                end

                local function LoadMyStories()
                    ClearMyStories()
                    local ok, stories = pcall(function()
                        return GetUserStoriesFunction:InvokeServer(player.UserId)
                    end)
                    if not ok or not stories then
                        return
                    end
                    for i = #stories, 1, -1 do
                        local card = CreateCard(profileScr, stories[i], false)
                        card.Name = "MyStoryCard"
                        card.LayoutOrder = 100 + (#stories - i)
                    end
                end

                -- ==================== PERFIL DE AUTOR ====================

                local authorProfileScr = Instance.new("ScrollingFrame")
                authorProfileScr.Size = UDim2.new(1, -30, 1, -20)
                authorProfileScr.Position = UDim2.new(0, 15, 0, 5)
                authorProfileScr.BackgroundTransparency = 1
                authorProfileScr.BorderSizePixel = 0
                authorProfileScr.ScrollBarThickness = 4
                authorProfileScr.ScrollBarImageColor3 = Colors.Primary
                authorProfileScr.Visible = false
                authorProfileScr.Parent = content
                screens.authorProfile = authorProfileScr

                local authorProfileList = Instance.new("UIListLayout")
                authorProfileList.Padding = UDim.new(0, 16)
                authorProfileList.SortOrder = Enum.SortOrder.LayoutOrder
                authorProfileList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                authorProfileList.Parent = authorProfileScr

                authorProfileList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    authorProfileScr.CanvasSize = UDim2.new(0, 0, 0, authorProfileList.AbsoluteContentSize.Y + 40)
                end)

                local backAuthorBtn = Btn(authorProfileScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function()
                    GoHome()
                end)
                backAuthorBtn.LayoutOrder = 1

                local authorNameLabel = Label(authorProfileScr, "", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Colors.White, 20)
                authorNameLabel.LayoutOrder = 2
                authorNameLabel.TextXAlignment = Enum.TextXAlignment.Left

                local authorMetaLabel = Label(authorProfileScr, "", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Colors.Gray, 14)
                authorMetaLabel.LayoutOrder = 3
                authorMetaLabel.TextXAlignment = Enum.TextXAlignment.Left

                -- ⭐ FUNCIÓN CORREGIDA: IR A PERFIL DE AUTOR
                function GoAuthorProfile(authorUserId)
                    print("[Client] 🔍 Navegando a perfil de autor:", authorUserId)

                    local ok, authorData = pcall(function()
                        return GetAuthorProfileFunction:InvokeServer(authorUserId)
                    end)

                    if not ok or not authorData then
                        warn("⚠️ Error al cargar perfil del autor")
                        return
                    end

                    currentAuthorProfile = authorData

                    authorNameLabel.Text = (authorData.displayName or authorData.name) .. " (@" .. authorData.name .. ")"
                    authorMetaLabel.Text = ("Historias: %d  •  Seguidores: %d  •  Siguiendo: %d"):format(authorData.storiesCount or 0, authorData.followers or 0, authorData.following or 0)

                    ShowScreen("authorProfile")
                end

                -- ⭐ FUNCIÓN CORREGIDA: CREAR TARJETA CON CLICK EN AUTOR FUNCIONANDO
                CreateCard = function(parent, story, isVertical)
                    local w, h = isVertical and 125 or 1, isVertical and 205 or 100
                    local card = Frame(parent, UDim2.new(isVertical and 0 or 1, isVertical and w or 0, 0, h), UDim2.new(0,0,0,0), Colors.CardBg, 8)
                    Stroke(card, Colors.Primary, 1)

                    local coverH = isVertical and 135 or 100
                    local coverW = isVertical and w or 75
                    local cover = Frame(card, UDim2.new(0, coverW, 0, coverH), UDim2.new(0,0,0,0), Colors.Primary, 8)
                    Round(cover, 8)
                    Label(cover, "📖", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Colors.White, 28)

                    if isVertical then
                        local info = Frame(card, UDim2.new(1,0,1,-135), UDim2.new(0,0,0,135), Colors.CardBg, 0)
                        info.BackgroundTransparency = 1
                        local t = Label(info, story.title, UDim2.new(1,-10,0,34), UDim2.new(0,5,0,4), Colors.White, 13)
                        t.TextXAlignment = Enum.TextXAlignment.Left
                        t.TextYAlignment = Enum.TextYAlignment.Top
                        t.Font = Enum.Font.GothamBold
                        Label(info, story.category, UDim2.new(1,-10,0,13), UDim2.new(0,5,1,-18), Colors.Gray, 11).TextXAlignment = Enum.TextXAlignment.Left
                    else
                        local info = Frame(card, UDim2.new(1, -89, 1, 0), UDim2.new(0, 89, 0, 0), Colors.Background, 0)
                        info.BackgroundTransparency = 1
                        local t = Label(info, story.title, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 6), Colors.White, 15)
                        t.TextXAlignment = Enum.TextXAlignment.Left
                        t.Font = Enum.Font.GothamBold

                        -- ⭐ CORREGIDO: Nombre del autor CLICKEABLE
                        local authorContainer = Frame(info, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 30), Colors.Background, 0)
                        authorContainer.BackgroundTransparency = 1
                        authorContainer.ZIndex = 10

                        local a = Label(authorContainer, "por " .. story.author, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Gray, 12)
                        a.TextXAlignment = Enum.TextXAlignment.Left
                        a.ZIndex = 11

                        -- Botón ENCIMA del texto del autor
                        local authorBtn = Instance.new("TextButton")
                        authorBtn.Size = UDim2.new(1, 0, 1, 0)
                        authorBtn.Position = UDim2.new(0, 0, 0, 0)
                        authorBtn.BackgroundTransparency = 1
                        authorBtn.Text = ""
                        authorBtn.ZIndex = 12
                        authorBtn.Parent = authorContainer
                        authorBtn.MouseButton1Click:Connect(function()
                            print("[Client] ✅ Click en autor:", story.author, "ID:", story.authorId)
                            GoAuthorProfile(story.authorId)
                        end)

                        -- Cambiar color al hover
                        authorBtn.MouseEnter:Connect(function()
                            a.TextColor3 = Colors.Primary
                        end)
                        authorBtn.MouseLeave:Connect(function()
                            a.TextColor3 = Colors.Gray
                        end)

                        local s = Label(info, "👁️ " .. (story.views or 0) .. "  •  " .. story.category, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 52), Colors.DarkGray, 11)
                        s.TextXAlignment = Enum.TextXAlignment.Left
                    end

                    -- Click general en la card
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 1, 0)
                    btn.BackgroundTransparency = 1
                    btn.Text = ""
                    btn.ZIndex = 5
                    btn.Parent = card
                    btn.MouseButton1Click:Connect(function()
                        GoDetails(story)
                    end)

                    return card
                end

                -- ⭐ EVENTOS DE TIEMPO REAL
                StoryUpdatedEvent.OnClientEvent:Connect(function(storyId)
                    print("[Client] 🔄 Historia actualizada:", storyId)
                    -- Recargar si estamos viendo esa historia
                    if currentStory and currentStory.id == storyId then
                        local ok, updatedStory = pcall(function()
                            return GetStoryByIdFunction:InvokeServer(storyId)
                        end)
                        if ok and updatedStory then
                            GoDetails(updatedStory)
                        end
                    end
                    -- Recargar listas
                    task.delay(0.5, function()
                        if currentScreen == "home" then
                            LoadStories()
                        elseif currentScreen == "search" then
                            FilterSearchResults(selectedCatPill)
                        end
                    end)
                end)

                AuthorUpdatedEvent.OnClientEvent:Connect(function(userId)
                    print("[Client] 🔄 Autor actualizado:", userId)
                    -- Si estamos viendo ese perfil, recargar
                    if currentAuthorProfile and currentAuthorProfile.userId == userId then
                        GoAuthorProfile(userId)
                    end
                end)
                -- Mostrar detalles de historia
                GoDetails = function(story)
                    currentStory = story
                    if not story then return end

                    IncrementViewEvent:FireServer(story.id)
                    detailsTitle.Text = story.title or "Sin título"
                    detailsMeta.Text = ("por %s  •  %s  •  👁️ %d"):format(story.author or "Desconocido", story.category or "Sin categoría", story.views or 0)
                    detailsSynopsis.Text = story.synopsis ~= "" and ("Sinopsis:" .. string.char(10) .. story.synopsis) or ("Sinopsis:" .. string.char(10) .. "Sin descripción")
                    detailsContent.Text = story.content ~= "" and ("Contenido:" .. string.char(10) .. story.content) or ("Contenido:" .. string.char(10) .. "Sin contenido")
                    ShowScreen("details")
                end

                -- Navegación


                function ShowScreen(name)
                    for n, s in pairs(screens) do
                        s.Visible = (n == name)
                    end
                    currentScreen = name
                end

                local function HighlightNav(name)
                    for _, n in pairs(navBtns) do
                        n.icon.TextColor3 = Colors.Gray
                        n.text.TextColor3 = Colors.Gray
                    end
                    if navBtns[name] then
                        navBtns[name].icon.TextColor3 = Colors.Primary
                        navBtns[name].text.TextColor3 = Colors.Primary
                    end
                end

                GoHome = function()
                    ShowScreen("home")
                    HighlightNav("Inicio")
                    LoadStories()
                end

                -- Tarjeta simple de autor para búsqueda
                local function CreateAuthorCard(parent, authorData)
                    local card = Frame(parent, UDim2.new(1, 0, 0, 86), UDim2.new(0,0,0,0), Colors.CardBg, 8)
                    Stroke(card, Colors.Primary, 1)
                    Label(card, "👤", UDim2.new(0, 48, 1, 0), UDim2.new(0, 8, 0, 0), Colors.White, 24)
                    local nameLbl = Label(card, authorData.displayName or authorData.name or "Autor", UDim2.new(1, -64, 0, 22), UDim2.new(0, 56, 0, 12), Colors.White, 15)
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.Font = Enum.Font.GothamBold
                    local metaLbl = Label(card, ("@%s  •  %d historias  •  %d seguidores"):format(authorData.name or "", authorData.storiesCount or 0, authorData.followers or 0), UDim2.new(1, -64, 0, 18), UDim2.new(0, 56, 0, 40), Colors.Gray, 12)
                    metaLbl.TextXAlignment = Enum.TextXAlignment.Left

                    local clickBtn = Instance.new("TextButton")
                    clickBtn.Size = UDim2.new(1, 0, 1, 0)
                    clickBtn.BackgroundTransparency = 1
                    clickBtn.Text = ""
                    clickBtn.Parent = card
                    clickBtn.MouseButton1Click:Connect(function()
                        GoAuthorProfile(authorData.userId)
                    end)
                    return card
                end

                GoSearch = function()
                    ShowScreen("search")
                    HighlightNav("Buscar")
                    if FilterSearchResults then FilterSearchResults(selectedCatPill) end
                end

                GoCreate = function()
                    ShowScreen("create")
                    HighlightNav("Publicar")
                end

                GoProfile = function()
                    ShowScreen("profile")
                    HighlightNav("Perfil")
                    LoadMyStories()
                end

                -- ⭐ LoadStories actualizado
                LoadStories = function()
                    for _, carousel in pairs(carousels) do
                        for _, c in ipairs(carousel:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                    end
                    local ok, stories = pcall(function() return GetAllStoriesFunction:InvokeServer() end)
                        if ok and stories then
                            LocalStoriesCache = stories
                            for i = #stories, 1, -1 do
                                local s = stories[i]
                                if carousels[s.category] then CreateCard(carousels[s.category], s, true) end
                            end
                        end
                    end

                    -- ⭐ FilterSearchResults MEJORADO
                    FilterSearchResults = function(category)
                        for _, c in ipairs(searchScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

                        searchSpinner.Visible = true
                        startSearchSpinner()
                        resultCountLabel.Visible = false

                        task.wait(0.1)

                        if currentSearchTab == "historias" then
                            local ok, stories
                            if searchBox.Text ~= "" then
                                ok, stories = pcall(function() return SearchStoriesFunction:InvokeServer(searchBox.Text) end)
                                else
                                    ok, stories = pcall(function() return GetAllStoriesFunction:InvokeServer() end)
                                    end

                                        task.wait(0.3)

                                        if not ok then
                                            stopSearchSpinner()
                                            searchSpinner.Visible = false
                                            resultCountLabel.Visible = true
                                            return
                                        end

                                        local filtered = {}
                                        for _, s in ipairs(stories or {}) do
                                            if not category or category == "De Todo" or s.category == category then
                                                table.insert(filtered, s)
                                            end
                                        end

                                        resultCountLabel.Text = tostring(#filtered) .. " Historias"
                                        for i = #filtered, 1, -1 do
                                            CreateCard(searchScroll, filtered[i], false)
                                        end
                                    else
                                        -- Buscar autores
                                        local ok, authors = pcall(function()
                                            return SearchAuthorsFunction:InvokeServer(searchBox.Text)
                                        end)

                                        task.wait(0.3)

                                        if not ok then
                                            stopSearchSpinner()
                                            searchSpinner.Visible = false
                                            resultCountLabel.Visible = true
                                            return
                                        end

                                        resultCountLabel.Text = tostring(#authors) .. " Autores"

                                        for i = #authors, 1, -1 do
                                            CreateAuthorCard(searchScroll, authors[i])
                                        end
                                    end

                                    stopSearchSpinner()
                                    searchSpinner.Visible = false
                                    resultCountLabel.Visible = true
                                end

                                -- Búsqueda con debounce
                                local searchDebounce = nil
                                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                                    if searchDebounce then
                                        task.cancel(searchDebounce)
                                    end
                                    searchDebounce = task.delay(0.5, function()
                                        if FilterSearchResults then FilterSearchResults(selectedCatPill) end
                                    end)
                                end)

                                -- ============= INICIAR =============
                                wait(1)
                                GoHome()
                                print("[Client] ✅ Wattpad v4.1 (Tiempo Real) Listo.")
