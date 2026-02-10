-- LOCAL SCRIPT - Wattpad Clone UI v4.0 ROBLOX STYLE
-- Colocar en StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[Client] Iniciando Wattpad UI v4 (Roblox Style)...")

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

-- Autores y Seguidores
local GetAuthorProfileFunction = RemoteFolder:WaitForChild("GetAuthorProfile")
local FollowAuthorEvent = RemoteFolder:WaitForChild("FollowAuthor")
local UnfollowAuthorEvent = RemoteFolder:WaitForChild("UnfollowAuthor")
local SearchAuthorsFunction = RemoteFolder:WaitForChild("SearchAuthors")
local GetAllAuthorsFunction = RemoteFolder:WaitForChild("GetAllAuthors")

-- Notificaciones
local GetNotificationsFunction = RemoteFolder:WaitForChild("GetNotifications")
local MarkNotificationReadEvent = RemoteFolder:WaitForChild("MarkNotificationRead")
local ClearAllNotificationsEvent = RemoteFolder:WaitForChild("ClearAllNotifications")

-- Soporte
local SendSupportTicketEvent = RemoteFolder:WaitForChild("SendSupportTicket")
local GetSupportTicketsFunction = RemoteFolder:WaitForChild("GetSupportTickets")
local ReplySupportTicketEvent = RemoteFolder:WaitForChild("ReplySupportTicket")

-- Verificación
local VerifyUserEvent = RemoteFolder:WaitForChild("VerifyUser")
local UnverifyUserEvent = RemoteFolder:WaitForChild("UnverifyUser")
local GetAllUsersFunction = RemoteFolder:WaitForChild("GetAllUsers")

print("[Client] Todos los RemoteEvents cargados")

-- Categorías
local Categories = {
"Romance", "Fantasía", "Ciencia Ficción", "Misterio",
"Terror", "Aventura", "Drama", "Comedia",
"Fanfic", "Poesía", "Acción", "Thriller"
}

-- COLORES ESTILO ROBLOX (Azul FUERTE/OSCURO como la app real)
local Colors = {
Primary = Color3.fromRGB(0, 102, 255), -- Azul FUERTE Roblox
Secondary = Color3.fromRGB(76, 151, 255), -- Azul medio
Background = Color3.fromRGB(25, 27, 29), -- Fondo oscuro Roblox
CardBg = Color3.fromRGB(35, 38, 42), -- Tarjetas
White = Color3.fromRGB(255, 255, 255),
Gray = Color3.fromRGB(189, 190, 190),
DarkGray = Color3.fromRGB(117, 117, 117),
Accent = Color3.fromRGB(0, 102, 255),
Success = Color3.fromRGB(2, 183, 87),
Warning = Color3.fromRGB(255, 168, 0),
LightBg = Color3.fromRGB(57, 59, 61) -- Fondo claro para contraste
}

-- Variables de estado
local currentScreen = "home"
local currentStory = nil
local editingStoryId = nil
local currentAuthorProfile = nil
local unreadNotifications = 0
local isAdmin = (player.Name == "Vegetl_t") -- Administrador

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

-- Función para crear icono de verificación
local function CreateVerifiedBadge(parent, size, position)
    local badge = Frame(parent, size, position, Colors.Primary, size.Y.Offset / 2)
    
    -- Símbolo de verificación (✓)
    local checkmark = Label(badge, "✓", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.White, size.Y.Offset * 0.7)
    checkmark.Font = Enum.Font.GothamBold
    
    return badge
end

-- ============= ANIMACIÓN DE CARGA MEJORADA =============

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
    
    -- Punto decorativo
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

-- ============= CONTENEDOR PRINCIPAL =============

local main = Frame(gui, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)

-- ============= NAVBAR INFERIOR ESTILO ROBLOX =============

local navbar = Frame(main, UDim2.new(1, 0, 0, 67), UDim2.new(0, 0, 1, -67), Colors.CardBg, 0)
-- Línea superior del navbar
local navLine = Frame(navbar, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), Colors.Primary, 0)

local navBtns = {}

local function NavBtn(icon, text, xPos, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 1, 0)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = navbar
    
    local iconL = Label(btn, icon, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 10), Colors.Gray, 22)
    local textL = Label(btn, text, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 40), Colors.Gray, 11)
    textL.Font = Enum.Font.GothamMedium
    
    -- Badge de notificaciones
    local badge = nil
    if text == "Notif" then
        badge = Frame(btn, UDim2.new(0, 18, 0, 18), UDim2.new(0.5, 8, 0, 8), Colors.Primary, 9)
        badge.Visible = false
        local badgeNum = Label(badge, "0", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.White, 10)
        badgeNum.Font = Enum.Font.GothamBold
    end
    
    btn.MouseButton1Click:Connect(function()
        for _, n in pairs(navBtns) do
            n.icon.TextColor3 = Colors.Gray
            n.text.TextColor3 = Colors.Gray
        end
        iconL.TextColor3 = Colors.Primary
        textL.TextColor3 = Colors.Primary
        if onClick then onClick() end
    end)
    
    navBtns[text] = {btn = btn, icon = iconL, text = textL, badge = badge}
    return btn
end

NavBtn("🏠", "Inicio", 0, function() GoHome() end)
    NavBtn("🔍", "Buscar", 0.2, function() GoSearch() end)
        NavBtn("✏️", "Publicar", 0.4, function() GoCreate() end)
            NavBtn("🔔", "Notif", 0.6, function() GoNotifications() end)
                NavBtn("👤", "Perfil", 0.8, function() GoProfile() end)
                    
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
                    
                    -- Título de la app "Wemix" centrado arriba
                    local appTitle = Label(homeScr, "Wemix", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), Colors.Primary, 28)
                    appTitle.LayoutOrder = 1
                    appTitle.TextXAlignment = Enum.TextXAlignment.Center
                    appTitle.Font = Enum.Font.GothamBold
                    
                    -- Título de sección "Historias"
                    local homeTitle = Label(homeScr, "Historias", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                    homeTitle.LayoutOrder = 2
                    homeTitle.TextXAlignment = Enum.TextXAlignment.Left
                    
                    -- Carruseles por categoría
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
                    
                    -- ==================== BUSCAR (ARREGLADO) ====================
                    
                    local searchScr = Frame(content, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                    searchScr.Visible = false
                    searchScr.BackgroundTransparency = 1
                    screens.search = searchScr
                    
                    -- BARRA DE BÚSQUEDA (ARREGLADA - MÁS PEQUEÑA Y BIEN POSICIONADA)
                    local searchBarContainer = Frame(searchScr, UDim2.new(1, -30, 0, 45), UDim2.new(0, 15, 0, 25), Colors.Background, 0)
                    searchBarContainer.BackgroundTransparency = 1
                    
                    local searchBarBg = Frame(searchBarContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.LightBg, 8)
                    Stroke(searchBarBg, Colors.Primary, 2)
                    
                    local searchIcon = Label(searchBarBg, "🔍", UDim2.new(0, 30, 1, 0), UDim2.new(0, 8, 0, 0), Colors.Gray, 16)
                    
                    local searchBox = Instance.new("TextBox")
                    searchBox.Size = UDim2.new(1, -50, 1, 0)
                    searchBox.Position = UDim2.new(0, 40, 0, 0)
                    searchBox.BackgroundTransparency = 1
                    searchBox.PlaceholderText = "Buscar historias..."
                    searchBox.PlaceholderColor3 = Colors.DarkGray
                    searchBox.Text = ""
                    searchBox.TextColor3 = Colors.White
                    searchBox.Font = Enum.Font.Gotham
                    searchBox.TextSize = 15
                    searchBox.TextXAlignment = Enum.TextXAlignment.Left
                    searchBox.TextYAlignment = Enum.TextYAlignment.Center
                    searchBox.ClearTextOnFocus = false
                    searchBox.Parent = searchBarBg
                    
                    -- Spinner de carga para búsqueda
                    local searchSpinner, startSearchSpinner, stopSearchSpinner = CreateLoadingSpinner(searchScr)
                    
                    -- Categorías como pills horizontales (DESPEGADAS DE LA BARRA)
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
                            
                            FilterSearchResults(cat)
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
                    
                    -- TABS: Historias / Autores
                    local searchTabsFrame = Frame(searchScr, UDim2.new(1, -30, 0, 40), UDim2.new(0, 15, 0, 131), Colors.Background, 0)
                    searchTabsFrame.BackgroundTransparency = 1
                    
                    local currentSearchTab = "historias"
                    
                    local tabHistoriasBtn, tabAutoresBtn
                    tabHistoriasBtn = Btn(searchTabsFrame, "📚 Historias", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                        currentSearchTab = "historias"
                        tabHistoriasBtn.BackgroundColor3 = Colors.Primary
                        tabAutoresBtn.BackgroundColor3 = Colors.CardBg
                        tabHistoriasBtn.TextLabel.TextColor3 = Colors.White
                        tabAutoresBtn.TextLabel.TextColor3 = Colors.Gray
                        FilterSearchResults(selectedCatPill)
                    end)
                    
                    tabAutoresBtn = Btn(searchTabsFrame, "👥 Autores", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                        currentSearchTab = "autores"
                        tabHistoriasBtn.BackgroundColor3 = Colors.CardBg
                        tabAutoresBtn.BackgroundColor3 = Colors.Primary
                        tabHistoriasBtn.TextLabel.TextColor3 = Colors.Gray
                        tabAutoresBtn.TextLabel.TextColor3 = Colors.White
                        FilterSearchResults(selectedCatPill)
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
                    
                    -- ==================== CREAR - FORMULARIO ====================
                    
                    local createScr = Instance.new("ScrollingFrame")
                    createScr.Size = UDim2.new(1, -30, 1, -20)
                    createScr.Position = UDim2.new(0, 15, 0, 5)
                    createScr.BackgroundTransparency = 1
                    createScr.BorderSizePixel = 0
                    createScr.ScrollBarThickness = 4
                    createScr.ScrollBarImageColor3 = Colors.Primary
                    createScr.Visible = false
                    createScr.Parent = content
                    screens.create = createScr
                    
                    local createList = Instance.new("UIListLayout")
                    createList.Padding = UDim.new(0, 14)
                    createList.SortOrder = Enum.SortOrder.LayoutOrder
                    createList.Parent = createScr
                    
                    createList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        createScr.CanvasSize = UDim2.new(0, 0, 0, createList.AbsoluteContentSize.Y + 40)
                    end)
                    
                    local formTitle = Label(createScr, "📝 Nueva Historia", UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), Colors.White, 23)
                    formTitle.LayoutOrder = 1
                        formTitle.TextXAlignment = Enum.TextXAlignment.Left
                            
                            local nameSection = Frame(createScr, UDim2.new(1, 0, 0, 85), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                            nameSection.LayoutOrder = 2
                            nameSection.BackgroundTransparency = 1
                            Label(nameSection, "Título", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), Colors.Gray, 13).TextXAlignment = Enum.TextXAlignment.Left
                            local titleInput = Input(nameSection, "Ej. El Secreto del Bosque", UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 22), false)
                            
                            local synSection = Frame(createScr, UDim2.new(1, 0, 0, 135), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                            synSection.LayoutOrder = 3
                            synSection.BackgroundTransparency = 1
                            Label(synSection, "Descripción", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), Colors.Gray, 13).TextXAlignment = Enum.TextXAlignment.Left
                            local synInput = Input(synSection, "¿De qué trata tu historia?", UDim2.new(1, 0, 0, 95), UDim2.new(0, 0, 0, 22), true)
                            
                            local catSection = Frame(createScr, UDim2.new(1, 0, 0, 85), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                            catSection.LayoutOrder = 4
                            catSection.BackgroundTransparency = 1
                            Label(catSection, "Categoría", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), Colors.Gray, 13).TextXAlignment = Enum.TextXAlignment.Left
                            local catDropdown = Frame(catSection, UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 22), Colors.CardBg, 8)
                            local catDisplay = Label(catDropdown, formData.category, UDim2.new(1, -40, 1, 0), UDim2.new(0, 14, 0, 0), Colors.White, 15)
                            catDisplay.TextXAlignment = Enum.TextXAlignment.Left
                            local catArrow = Label(catDropdown, "▼", UDim2.new(0, 20, 1, 0), UDim2.new(1, -28, 0, 0), Colors.Gray, 13)
                            
                            local catBtn = Instance.new("TextButton")
                            catBtn.Size = UDim2.new(1, 0, 1, 0)
                            catBtn.BackgroundTransparency = 1
                            catBtn.Text = ""
                            catBtn.Parent = catDropdown
                            local catExpanded = false
                            local catList = nil
                            
                            catBtn.MouseButton1Click:Connect(function()
                                if not catExpanded then
                                    catList = Instance.new("ScrollingFrame")
                                    catList.Size = UDim2.new(1, 0, 0, 190)
                                    catList.Position = UDim2.new(0, 0, 1, 5)
                                    catList.BackgroundColor3 = Colors.CardBg
                                    catList.BorderSizePixel = 0
                                    catList.ScrollBarThickness = 4
                                    catList.ZIndex = 10
                                    catList.Parent = catDropdown
                                    Round(catList, 8)
                                    
                                    local listLayout = Instance.new("UIListLayout")
                                    listLayout.Padding = UDim.new(0, 0)
                                    listLayout.Parent = catList
                                    
                                    for _, cat in ipairs(Categories) do
                                        local optBtn, _ = Btn(catList, cat, UDim2.new(1, 0, 0, 38), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                                            formData.category = cat
                                                catDisplay.Text = cat
                                                if catList then catList:Destroy(); catList = nil end
                                                catExpanded = false
                                            end)
                                            optBtn.BorderSizePixel = 0
                                            local sep = Frame(optBtn, UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 1, -1), Colors.Background, 0)
                                            sep.BorderSizePixel = 0
                                        end
                                        
                                        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                            if catList then
                                                catList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
                                            end
                                        end)
                                        catExpanded = true
                                    else
                                        if catList then catList:Destroy(); catList = nil end
                                        catExpanded = false
                                    end
                                end)
                                
                                local statusSection = Frame(createScr, UDim2.new(1, 0, 0, 85), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                statusSection.LayoutOrder = 5
                                statusSection.BackgroundTransparency = 1
                                Label(statusSection, "Estado", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), Colors.Gray, 13).TextXAlignment = Enum.TextXAlignment.Left
                                local statusBtns = Frame(statusSection, UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 22), Colors.Background, 0)
                                statusBtns.BackgroundTransparency = 1
                                
                                local progressBtn, completeBtn
                                progressBtn = Btn(statusBtns, "En Progreso", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Warning, Colors.Background, function()
                                    formData.status = "En progreso"
                                        progressBtn.BackgroundColor3 = Colors.Warning
                                        completeBtn.BackgroundColor3 = Colors.CardBg
                                        completeBtn.TextLabel.TextColor3 = Colors.Gray
                                        progressBtn.TextLabel.TextColor3 = Colors.Background
                                    end)
                                    completeBtn = Btn(statusBtns, "Completa", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                                        formData.status = "Completa"
                                            progressBtn.BackgroundColor3 = Colors.CardBg
                                            completeBtn.BackgroundColor3 = Colors.Success
                                            progressBtn.TextLabel.TextColor3 = Colors.Gray
                                            completeBtn.TextLabel.TextColor3 = Colors.White
                                        end)
                                        
                                        local continueBtn, _ = Btn(createScr, "Siguiente Paso →", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                            formData.title = titleInput.Text
                                                formData.synopsis = synInput.Text
                                                    if formData.title == "" then warn("⚠️ Falta título"); return end
                                                    GoWrite()
                                                end)
                                                continueBtn.LayoutOrder = 7
                                                
                                                -- ==================== ESCRIBIR ====================
                                                
                                                local writeScr = Instance.new("ScrollingFrame")
                                                writeScr.Size = UDim2.new(1, -30, 1, -20)
                                                writeScr.Position = UDim2.new(0, 15, 0, 5)
                                                writeScr.BackgroundTransparency = 1
                                                writeScr.BorderSizePixel = 0
                                                writeScr.ScrollBarThickness = 4
                                                writeScr.Visible = false
                                                writeScr.Parent = content
                                                screens.write = writeScr
                                                
                                                local writeList = Instance.new("UIListLayout")
                                                writeList.Padding = UDim.new(0, 14)
                                                writeList.SortOrder = Enum.SortOrder.LayoutOrder
                                                writeList.Parent = writeScr
                                                
                                                writeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                    writeScr.CanvasSize = UDim2.new(0, 0, 0, writeList.AbsoluteContentSize.Y + 40)
                                                end)
                                                
                                                local backBtn, _ = Btn(writeScr, "← Volver", UDim2.new(0, 95, 0, 34), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function() GoCreate() end)
                                                    backBtn.LayoutOrder = 1
                                                    
                                                    local writeTitle = Label(writeScr, "Contenido de la Historia", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0), Colors.White, 19)
                                                    writeTitle.LayoutOrder = 2
                                                    writeTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                    
                                                    local writeArea = Frame(writeScr, UDim2.new(1, 0, 0, 380), UDim2.new(0, 0, 0, 0), Colors.CardBg, 10)
                                                    writeArea.LayoutOrder = 4
                                                    local contentInput = Instance.new("TextBox")
                                                    contentInput.Size = UDim2.new(1, -24, 1, -24)
                                                    contentInput.Position = UDim2.new(0, 12, 0, 12)
                                                    contentInput.BackgroundTransparency = 1
                                                    contentInput.PlaceholderText = "Empieza a escribir aquí..."
                                                    contentInput.PlaceholderColor3 = Colors.DarkGray
                                                    contentInput.Text = ""
                                                    contentInput.TextColor3 = Colors.White
                                                    contentInput.Font = Enum.Font.Gotham
                                                    contentInput.TextSize = 15
                                                    contentInput.TextXAlignment = Enum.TextXAlignment.Left
                                                    contentInput.TextYAlignment = Enum.TextYAlignment.Top
                                                    contentInput.MultiLine = true
                                                    contentInput.TextWrapped = true
                                                    contentInput.ClearTextOnFocus = false
                                                    contentInput.Parent = writeArea
                                                    
                                                    local publishBtn, _ = Btn(writeScr, "PUBLICAR HISTORIA", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                                        formData.content = contentInput.Text
                                                            if formData.content == "" then warn("⚠️ Escribe algo"); return end
                                                            
                                                            if editingStoryId then
                                                                UpdateStoryEvent:FireServer(editingStoryId, formData)
                                                            else
                                                                PublishStoryEvent:FireServer(formData)
                                                            end
                                                            
                                                            -- Reset
                                                            titleInput.Text = ""
                                                            synInput.Text = ""
                                                            contentInput.Text = ""
                                                            formData.title = ""
                                                                formData.synopsis = ""
                                                                    GoHome()
                                                                    wait(0.6)
                                                                    LoadStories()
                                                                end)
                                                                publishBtn.LayoutOrder = 5
                                                                
                                                                -- ==================== PERFIL ====================
                                                                
                                                                local profileScr = Instance.new("ScrollingFrame")
                                                                profileScr.Size = UDim2.new(1, -30, 1, -20)
                                                                profileScr.Position = UDim2.new(0, 15, 0, 5)
                                                                profileScr.BackgroundTransparency = 1
                                                                profileScr.BorderSizePixel = 0
                                                                profileScr.ScrollBarThickness = 4
                                                                profileScr.Visible = false
                                                                profileScr.Parent = content
                                                                screens.profile = profileScr
                                                                
                                                                local profileList = Instance.new("UIListLayout")
                                                                profileList.Padding = UDim.new(0, 16)
                                                                profileList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                profileList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                                                                profileList.Parent = profileScr
                                                                
                                                                profileList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                    profileScr.CanvasSize = UDim2.new(0, 0, 0, profileList.AbsoluteContentSize.Y + 40)
                                                                end)
                                                                
                                                                local avatarSection = Frame(profileScr, UDim2.new(1, 0, 0, 175), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                avatarSection.LayoutOrder = 1
                                                                avatarSection.BackgroundTransparency = 1
                                                                
                                                                local avatarFrame = Frame(avatarSection, UDim2.new(0, 85, 0, 85), UDim2.new(0.5, -42.5, 0, 8), Colors.CardBg, 42.5)
                                                                Stroke(avatarFrame, Colors.Primary, 3)
                                                                local avatarImg = Instance.new("ImageLabel")
                                                                avatarImg.Size = UDim2.new(1, 0, 1, 0)
                                                                avatarImg.BackgroundTransparency = 1
                                                                avatarImg.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                                                                avatarImg.Parent = avatarFrame
                                                                Round(avatarImg, 42.5)
                                                                
                                                                local profileName = Label(avatarSection, player.DisplayName, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 103), Colors.White, 21)
                                                                profileName.TextXAlignment = Enum.TextXAlignment.Center
                                                                profileName.Font = Enum.Font.GothamBold
                                                                local profileUsername = Label(avatarSection, "@" .. player.Name, UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 130), Colors.Gray, 13)
                                                                profileUsername.TextXAlignment = Enum.TextXAlignment.Center
                                                                
                                                                -- Botón de ajustes (arriba a la derecha)
                                                                local settingsBtn, _ = Btn(profileScr, "⚙️", UDim2.new(0, 40, 0, 40), UDim2.new(1, -50, 0, 10), Colors.CardBg, Colors.White, function()
                                                                    GoSettings()
                                                                end)
                                                                settingsBtn.LayoutOrder = 0
                                                                
                                                                local profileStatsFrame = Frame(profileScr, UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                profileStatsFrame.LayoutOrder = 2
                                                                profileStatsFrame.BackgroundTransparency = 1
                                                                local profileStoriesCount = Label(profileStatsFrame, "0", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Colors.White, 19)
                                                                profileStoriesCount.TextXAlignment = Enum.TextXAlignment.Center
                                                                Label(profileStatsFrame, "Obras Publicadas", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 24), Colors.Gray, 12).TextXAlignment = Enum.TextXAlignment.Center
                                                                
                                                                local divider = Frame(profileScr, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), Colors.LightBg, 0)
                                                                divider.LayoutOrder = 3
                                                                
                                                                local myStoriesTitle = Label(profileScr, "Mis Historias", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Colors.White, 17)
                                                                myStoriesTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                myStoriesTitle.LayoutOrder = 4
                                                                
                                                                local storiesContainer = Frame(profileScr, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                storiesContainer.LayoutOrder = 5
                                                                storiesContainer.BackgroundTransparency = 1
                                                                storiesContainer.AutomaticSize = Enum.AutomaticSize.Y
                                                                local storiesList = Instance.new("UIListLayout")
                                                                storiesList.Padding = UDim.new(0, 10)
                                                                storiesList.Parent = storiesContainer
                                                                
                                                                -- ==================== DETALLES ====================
                                                                
                                                                local detailsScr = Instance.new("ScrollingFrame")
                                                                detailsScr.Size = UDim2.new(1, -30, 1, -20)
                                                                detailsScr.Position = UDim2.new(0, 15, 0, 5)
                                                                detailsScr.BackgroundTransparency = 1
                                                                detailsScr.BorderSizePixel = 0
                                                                detailsScr.ScrollBarThickness = 4
                                                                detailsScr.ScrollBarImageColor3 = Colors.Primary
                                                                detailsScr.Visible = false
                                                                detailsScr.Parent = content
                                                                screens.details = detailsScr
                                                                
                                                                local detailsList = Instance.new("UIListLayout")
                                                                detailsList.Padding = UDim.new(0, 16)
                                                                detailsList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                detailsList.Parent = detailsScr
                                                                
                                                                detailsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                    detailsScr.CanvasSize = UDim2.new(0, 0, 0, detailsList.AbsoluteContentSize.Y + 50)
                                                                end)
                                                                
                                                                local backDetailsBtn, _ = Btn(detailsScr, "←", UDim2.new(0, 38, 0, 38), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function()
                                                                    GoHome()
                                                                end)
                                                                backDetailsBtn.LayoutOrder = 1
                                                                
                                                                local heroContainer = Frame(detailsScr, UDim2.new(1, 0, 0, 185), UDim2.new(0,0,0,0), Colors.Background, 0)
                                                                heroContainer.BackgroundTransparency = 1
                                                                heroContainer.LayoutOrder = 2
                                                                
                                                                local coverFrame = Frame(heroContainer, UDim2.new(0, 115, 0, 175), UDim2.new(0, 5, 0, 5), Colors.CardBg, 8)
                                                                Stroke(coverFrame, Colors.Primary, 2)
                                                                local coverGradient = Frame(coverFrame, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Colors.Primary, 8)
                                                                local coverIcon = Label(coverGradient, "📖", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Colors.White, 38)
                                                                
                                                                local infoFrame = Frame(heroContainer, UDim2.new(1, -135, 1, 0), UDim2.new(0, 135, 0, 5), Colors.Background, 0)
                                                                infoFrame.BackgroundTransparency = 1
                                                                
                                                                local detailsTitle = Label(infoFrame, "Título de Historia", UDim2.new(1, 0, 0, 58), UDim2.new(0, 0, 0, 0), Colors.White, 23)
                                                                detailsTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                detailsTitle.TextYAlignment = Enum.TextYAlignment.Top
                                                                detailsTitle.Font = Enum.Font.GothamBold
                                                                
                                                                local authorRow = Frame(infoFrame, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 68), Colors.Background, 0)
                                                                authorRow.BackgroundTransparency = 1
                                                                
                                                                local authorAvatar = Frame(authorRow, UDim2.new(0, 22, 0, 22), UDim2.new(0, 0, 0, 3), Colors.CardBg, 11)
                                                                local authorImg = Instance.new("ImageLabel")
                                                                authorImg.Size = UDim2.new(1, 0, 1, 0)
                                                                authorImg.BackgroundTransparency = 1
                                                                authorImg.Parent = authorAvatar
                                                                Round(authorImg, 11)
                                                                
                                                                local authorName = Label(authorRow, "Usuario", UDim2.new(1, -28, 1, 0), UDim2.new(0, 30, 0, 0), Colors.Gray, 13)
                                                                authorName.TextXAlignment = Enum.TextXAlignment.Left
                                                                
                                                                local statsTextRow = Frame(infoFrame, UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 100), Colors.Background, 0)
                                                                statsTextRow.BackgroundTransparency = 1
                                                                local statsLabel = Label(statsTextRow, "👁️ 1.2K  •  ⭐ 56  •  En Progreso", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.DarkGray, 12)
                                                                statsLabel.TextXAlignment = Enum.TextXAlignment.Left
                                                                
                                                                local actionContainer = Frame(detailsScr, UDim2.new(1, 0, 0, 48), UDim2.new(0,0,0,0), Colors.Background, 0)
                                                                actionContainer.BackgroundTransparency = 1
                                                                actionContainer.LayoutOrder = 3
                                                                
                                                                local readBtn, _ = Btn(actionContainer, "LEER AHORA", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                                                    if currentStory then GoReader(currentStory) end
                                                                end)
                                                                
                                                                local detailDiv = Frame(detailsScr, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), Colors.LightBg, 0)
                                                                detailDiv.LayoutOrder = 4
                                                                
                                                                local tagsContainer = Frame(detailsScr, UDim2.new(1, 0, 0, 28), UDim2.new(0,0,0,0), Colors.Background, 0)
                                                                tagsContainer.BackgroundTransparency = 1
                                                                tagsContainer.LayoutOrder = 5
                                                                
                                                                local tagPill = Frame(tagsContainer, UDim2.new(0, 95, 1, 0), UDim2.new(0,0,0,0), Colors.CardBg, 14)
                                                                Stroke(tagPill, Colors.Primary, 1)
                                                                local tagText = Label(tagPill, "Romance", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Gray, 12)
                                                                
                                                                local synContainer = Frame(detailsScr, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                synContainer.LayoutOrder = 6
                                                                synContainer.AutomaticSize = Enum.AutomaticSize.Y
                                                                synContainer.BackgroundTransparency = 1
                                                                
                                                                local synHeader = Label(synContainer, "Sinopsis", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), Colors.White, 15)
                                                                synHeader.TextXAlignment = Enum.TextXAlignment.Left
                                                                synHeader.Font = Enum.Font.GothamBold
                                                                
                                                                local synBody = Label(synContainer, "Aquí va el texto de la sinopsis...", UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 28), Colors.Gray, 14)
                                                                synBody.TextXAlignment = Enum.TextXAlignment.Left
                                                                synBody.TextYAlignment = Enum.TextYAlignment.Top
                                                                synBody.AutomaticSize = Enum.AutomaticSize.Y
                                                                synBody.Font = Enum.Font.Gotham
                                                                
                                                                -- ==================== LECTOR ====================
                                                                
                                                                local readerScr = Instance.new("ScrollingFrame")
                                                                readerScr.Size = UDim2.new(1, -30, 1, -20)
                                                                readerScr.Position = UDim2.new(0, 15, 0, 5)
                                                                readerScr.BackgroundTransparency = 1
                                                                readerScr.BorderSizePixel = 0
                                                                readerScr.ScrollBarThickness = 4
                                                                readerScr.ScrollBarImageColor3 = Colors.Primary
                                                                readerScr.Visible = false
                                                                readerScr.Parent = content
                                                                screens.reader = readerScr
                                                                
                                                                local readerList = Instance.new("UIListLayout")
                                                                readerList.Padding = UDim.new(0, 14)
                                                                readerList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                readerList.Parent = readerScr
                                                                
                                                                readerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                    readerScr.CanvasSize = UDim2.new(0, 0, 0, readerList.AbsoluteContentSize.Y + 40)
                                                                end)
                                                                
                                                                local backReaderBtn, _ = Btn(readerScr, "← Salir", UDim2.new(0, 95, 0, 34), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function()
                                                                    if currentStory then GoDetails(currentStory) end
                                                                end)
                                                                backReaderBtn.LayoutOrder = 1
                                                                
                                                                local readerTitle = Label(readerScr, "", UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.White, 21)
                                                                readerTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                readerTitle.LayoutOrder = 2
                                                                readerTitle.AutomaticSize = Enum.AutomaticSize.Y
                                                                readerTitle.Font = Enum.Font.GothamBold
                                                                
                                                                local readerText = Label(readerScr, "", UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.Gray, 15)
                                                                readerText.Font = Enum.Font.Gotham
                                                                readerText.TextXAlignment = Enum.TextXAlignment.Left
                                                                readerText.TextYAlignment = Enum.TextYAlignment.Top
                                                                readerText.AutomaticSize = Enum.AutomaticSize.Y
                                                                readerText.LayoutOrder = 3
                                                                readerText.LineHeight = 1.5
                                                                
                                                                -- ==================== NOTIFICACIONES ====================
                                                                
                                                                local notifScr = Instance.new("ScrollingFrame")
                                                                notifScr.Size = UDim2.new(1, -30, 1, -20)
                                                                notifScr.Position = UDim2.new(0, 15, 0, 5)
                                                                notifScr.BackgroundTransparency = 1
                                                                notifScr.BorderSizePixel = 0
                                                                notifScr.ScrollBarThickness = 4
                                                                notifScr.ScrollBarImageColor3 = Colors.Primary
                                                                notifScr.Visible = false
                                                                notifScr.Parent = content
                                                                screens.notifications = notifScr
                                                                
                                                                local notifList = Instance.new("UIListLayout")
                                                                notifList.Padding = UDim.new(0, 10)
                                                                notifList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                notifList.Parent = notifScr
                                                                
                                                                notifList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                    notifScr.CanvasSize = UDim2.new(0, 0, 0, notifList.AbsoluteContentSize.Y + 40)
                                                                end)
                                                                
                                                                local notifTitle = Label(notifScr, "🔔 Notificaciones", UDim2.new(0.7, 0, 0, 35), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                                                                notifTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                notifTitle.LayoutOrder = 1
                                                                
                                                                local clearNotifBtn, _ = Btn(notifScr, "Limpiar Todo", UDim2.new(0.28, 0, 0, 35), UDim2.new(0.72, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                                                                    ClearAllNotificationsEvent:FireServer()
                                                                    for _, c in ipairs(notifScr:GetChildren()) do
                                                                        if c:IsA("Frame") and c.LayoutOrder > 1 then c:Destroy() end
                                                                    end
                                                                end)
                                                                clearNotifBtn.LayoutOrder = 1.5
                                                                
                                                                -- ==================== AJUSTES ====================
                                                                
                                                                local settingsScr = Instance.new("ScrollingFrame")
                                                                settingsScr.Size = UDim2.new(1, -30, 1, -20)
                                                                settingsScr.Position = UDim2.new(0, 15, 0, 5)
                                                                settingsScr.BackgroundTransparency = 1
                                                                settingsScr.BorderSizePixel = 0
                                                                settingsScr.ScrollBarThickness = 4
                                                                settingsScr.ScrollBarImageColor3 = Colors.Primary
                                                                settingsScr.Visible = false
                                                                settingsScr.Parent = content
                                                                screens.settings = settingsScr
                                                                
                                                                local settingsList = Instance.new("UIListLayout")
                                                                settingsList.Padding = UDim.new(0, 12)
                                                                settingsList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                settingsList.Parent = settingsScr
                                                                
                                                                settingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                    settingsScr.CanvasSize = UDim2.new(0, 0, 0, settingsList.AbsoluteContentSize.Y + 40)
                                                                end)
                                                                
                                                                local backSettingsBtn, _ = Btn(settingsScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function() GoProfile() end)
                                                                    backSettingsBtn.LayoutOrder = 1
                                                                    
                                                                    local settingsTitle = Label(settingsScr, "⚙️ Ajustes", UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                                                                    settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                    settingsTitle.LayoutOrder = 2
                                                                    
                                                                    -- Opciones de ajustes
                                                                    local supportOptionBtn, _ = Btn(settingsScr, "💬 Soporte", UDim2.new(1, 0, 0, 55), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function()
                                                                        if isAdmin then
                                                                            GoAdminSupport()
                                                                        else
                                                                            GoSupport()
                                                                        end
                                                                    end)
                                                                    supportOptionBtn.LayoutOrder = 3
                                                                    
                                                                    -- ==================== SOPORTE (Usuario) ====================
                                                                    
                                                                    local supportScr = Instance.new("ScrollingFrame")
                                                                    supportScr.Size = UDim2.new(1, -30, 1, -20)
                                                                    supportScr.Position = UDim2.new(0, 15, 0, 5)
                                                                    supportScr.BackgroundTransparency = 1
                                                                    supportScr.BorderSizePixel = 0
                                                                    supportScr.ScrollBarThickness = 4
                                                                    supportScr.ScrollBarImageColor3 = Colors.Primary
                                                                    supportScr.Visible = false
                                                                    supportScr.Parent = content
                                                                    screens.support = supportScr
                                                                    
                                                                    local supportList = Instance.new("UIListLayout")
                                                                    supportList.Padding = UDim.new(0, 14)
                                                                    supportList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                    supportList.Parent = supportScr
                                                                    
                                                                    supportList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                        supportScr.CanvasSize = UDim2.new(0, 0, 0, supportList.AbsoluteContentSize.Y + 40)
                                                                    end)
                                                                    
                                                                    local backSupportBtn, _ = Btn(supportScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function() GoSettings() end)
                                                                        backSupportBtn.LayoutOrder = 1
                                                                        
                                                                        local supportTitle = Label(supportScr, "💬 Enviar Reporte", UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), Colors.White, 22)
                                                                        supportTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                        supportTitle.LayoutOrder = 2
                                                                        
                                                                        local supportDescSection = Frame(supportScr, UDim2.new(1, 0, 0, 180), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                        supportDescSection.LayoutOrder = 3
                                                                        supportDescSection.BackgroundTransparency = 1
                                                                        Label(supportDescSection, "Describe tu problema", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), Colors.Gray, 13).TextXAlignment = Enum.TextXAlignment.Left
                                                                        local supportMessageInput = Input(supportDescSection, "Explica el problema que estás experimentando...", UDim2.new(1, 0, 0, 140), UDim2.new(0, 0, 0, 22), true)
                                                                        
                                                                        local sendSupportBtn, _ = Btn(supportScr, "Enviar Reporte", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                                                            if supportMessageInput.Text ~= "" then
                                                                                SendSupportTicketEvent:FireServer(supportMessageInput.Text)
                                                                                supportMessageInput.Text = ""
                                                                                GoSettings()
                                                                            end
                                                                        end)
                                                                        sendSupportBtn.LayoutOrder = 4
                                                                        
                                                                        -- ==================== ADMIN SOPORTE ====================
                                                                        
                                                                        local adminSupportScr = Instance.new("ScrollingFrame")
                                                                        adminSupportScr.Size = UDim2.new(1, -30, 1, -20)
                                                                        adminSupportScr.Position = UDim2.new(0, 15, 0, 5)
                                                                        adminSupportScr.BackgroundTransparency = 1
                                                                        adminSupportScr.BorderSizePixel = 0
                                                                        adminSupportScr.ScrollBarThickness = 4
                                                                        adminSupportScr.ScrollBarImageColor3 = Colors.Primary
                                                                        adminSupportScr.Visible = false
                                                                        adminSupportScr.Parent = content
                                                                        screens.adminSupport = adminSupportScr
                                                                        
                                                                        local adminSupportList = Instance.new("UIListLayout")
                                                                        adminSupportList.Padding = UDim.new(0, 10)
                                                                        adminSupportList.SortOrder = Enum.SortOrder.LayoutOrder
                                                                        adminSupportList.Parent = adminSupportScr
                                                                        
                                                                        adminSupportList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                                                                            adminSupportScr.CanvasSize = UDim2.new(0, 0, 0, adminSupportList.AbsoluteContentSize.Y + 40)
                                                                        end)
                                                                        
                                                                        local backAdminBtn, _ = Btn(adminSupportScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function() GoSettings() end)
                                                                            backAdminBtn.LayoutOrder = 1
                                                                            
                                                                            local adminTitle = Label(adminSupportScr, "👑 Panel de Administración", UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), Colors.Primary, 22)
                                                                            adminTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                            adminTitle.Font = Enum.Font.GothamBold
                                                                            adminTitle.LayoutOrder = 2
                                                                            
                                                                            -- Tabs: Tickets / Usuarios
                                                                            local adminTabsFrame = Frame(adminSupportScr, UDim2.new(1, 0, 0, 45), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                            adminTabsFrame.BackgroundTransparency = 1
                                                                            adminTabsFrame.LayoutOrder = 3
                                                                            
                                                                            local currentAdminTab = "tickets"
                                                                            local adminTab1Btn, adminTab2Btn
                                                                            
                                                                            adminTab1Btn = Btn(adminTabsFrame, "📩 Tickets", UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                                                                currentAdminTab = "tickets"
                                                                                adminTab1Btn.BackgroundColor3 = Colors.Primary
                                                                                adminTab2Btn.BackgroundColor3 = Colors.CardBg
                                                                                adminTab1Btn.TextLabel.TextColor3 = Colors.White
                                                                                adminTab2Btn.TextLabel.TextColor3 = Colors.Gray
                                                                                LoadAdminContent()
                                                                            end)
                                                                            
                                                                            adminTab2Btn = Btn(adminTabsFrame, "👥 Usuarios", UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Colors.CardBg, Colors.Gray, function()
                                                                                currentAdminTab = "users"
                                                                                adminTab1Btn.BackgroundColor3 = Colors.CardBg
                                                                                adminTab2Btn.BackgroundColor3 = Colors.Primary
                                                                                adminTab1Btn.TextLabel.TextColor3 = Colors.Gray
                                                                                adminTab2Btn.TextLabel.TextColor3 = Colors.White
                                                                                LoadAdminContent()
                                                                            end)
                                                                            
                                                                            local adminContentContainer = Frame(adminSupportScr, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                            adminContentContainer.LayoutOrder = 4
                                                                            adminContentContainer.BackgroundTransparency = 1
                                                                            adminContentContainer.AutomaticSize = Enum.AutomaticSize.Y
                                                                            
                                                                            local adminContentList = Instance.new("UIListLayout")
                                                                            adminContentList.Padding = UDim.new(0, 10)
                                                                            adminContentList.Parent = adminContentContainer
                                                                            
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
                                                                            
                                                                            local backAuthorBtn, _ = Btn(authorProfileScr, "← Volver", UDim2.new(0, 100, 0, 36), UDim2.new(0, 0, 0, 0), Colors.CardBg, Colors.White, function() GoHome() end)
                                                                                backAuthorBtn.LayoutOrder = 1
                                                                                
                                                                                local authorAvatarSection = Frame(authorProfileScr, UDim2.new(1, 0, 0, 180), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                                authorAvatarSection.LayoutOrder = 2
                                                                                authorAvatarSection.BackgroundTransparency = 1
                                                                                
                                                                                local authorAvatarFrame = Frame(authorAvatarSection, UDim2.new(0, 90, 0, 90), UDim2.new(0.5, -45, 0, 10), Colors.CardBg, 45)
                                                                                Stroke(authorAvatarFrame, Colors.Primary, 3)
                                                                                local authorAvatarImg = Instance.new("ImageLabel")
                                                                                authorAvatarImg.Size = UDim2.new(1, 0, 1, 0)
                                                                                authorAvatarImg.BackgroundTransparency = 1
                                                                                authorAvatarImg.Parent = authorAvatarFrame
                                                                                Round(authorAvatarImg, 45)
                                                                                
                                                                                local authorNameContainer = Frame(authorAvatarSection, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 110), Colors.Background, 0)
                                                                                authorNameContainer.BackgroundTransparency = 1
                                                                                
                                                                                local authorProfileName = Label(authorNameContainer, "Usuario", UDim2.new(0, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), Colors.White, 22)
                                                                                authorProfileName.TextXAlignment = Enum.TextXAlignment.Center
                                                                                authorProfileName.Font = Enum.Font.GothamBold
                                                                                authorProfileName.AutomaticSize = Enum.AutomaticSize.X
                                                                                authorProfileName.AnchorPoint = Vector2.new(0.5, 0)
                                                                                
                                                                                local authorVerifiedBadge = CreateVerifiedBadge(authorNameContainer, UDim2.new(0, 20, 0, 20), UDim2.new(0.5, 0, 0, 5))
                                                                                authorVerifiedBadge.Visible = false
                                                                                authorVerifiedBadge.AnchorPoint = Vector2.new(0, 0)
                                                                                
                                                                                local authorProfileUsername = Label(authorAvatarSection, "@username", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 138), Colors.Gray, 14)
                                                                                authorProfileUsername.TextXAlignment = Enum.TextXAlignment.Center
                                                                                
                                                                                local authorStatsFrame = Frame(authorProfileScr, UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                                authorStatsFrame.LayoutOrder = 3
                                                                                authorStatsFrame.BackgroundTransparency = 1
                                                                                
                                                                                local authorStat1Frame = Frame(authorStatsFrame, UDim2.new(0.33, -10, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                                authorStat1Frame.BackgroundTransparency = 1
                                                                                local authorStat1Num = Label(authorStat1Frame, "0", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 10), Colors.White, 20)
                                                                                authorStat1Num.Font = Enum.Font.GothamBold
                                                                                Label(authorStat1Frame, "Historias", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 36), Colors.Gray, 12)
                                                                                
                                                                                local authorStat2Frame = Frame(authorStatsFrame, UDim2.new(0.33, -10, 1, 0), UDim2.new(0.33, 5, 0, 0), Colors.Background, 0)
                                                                                authorStat2Frame.BackgroundTransparency = 1
                                                                                local authorStat2Num = Label(authorStat2Frame, "0", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 10), Colors.White, 20)
                                                                                authorStat2Num.Font = Enum.Font.GothamBold
                                                                                Label(authorStat2Frame, "Seguidores", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 36), Colors.Gray, 12)
                                                                                
                                                                                local authorStat3Frame = Frame(authorStatsFrame, UDim2.new(0.33, -10, 1, 0), UDim2.new(0.66, 10, 0, 0), Colors.Background, 0)
                                                                                authorStat3Frame.BackgroundTransparency = 1
                                                                                local authorStat3Num = Label(authorStat3Frame, "0", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 10), Colors.White, 20)
                                                                                authorStat3Num.Font = Enum.Font.GothamBold
                                                                                Label(authorStat3Frame, "Siguiendo", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 36), Colors.Gray, 12)
                                                                                
                                                                                local followBtnContainer = Frame(authorProfileScr, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                                followBtnContainer.LayoutOrder = 4
                                                                                followBtnContainer.BackgroundTransparency = 1
                                                                                
                                                                                local followBtn
                                                                                followBtn = Btn(followBtnContainer, "Seguir", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Colors.Primary, Colors.White, function()
                                                                                    if not currentAuthorProfile then return end
                                                                                    
                                                                                    if currentAuthorProfile.isFollowing then
                                                                                        UnfollowAuthorEvent:FireServer(currentAuthorProfile.userId)
                                                                                        currentAuthorProfile.isFollowing = false
                                                                                        currentAuthorProfile.followers = currentAuthorProfile.followers - 1
                                                                                        followBtn.BackgroundColor3 = Colors.Primary
                                                                                        followBtn.TextLabel.Text = "Seguir"
                                                                                        authorStat2Num.Text = tostring(currentAuthorProfile.followers)
                                                                                    else
                                                                                        FollowAuthorEvent:FireServer(currentAuthorProfile.userId)
                                                                                        currentAuthorProfile.isFollowing = true
                                                                                        currentAuthorProfile.followers = currentAuthorProfile.followers + 1
                                                                                        followBtn.BackgroundColor3 = Colors.CardBg
                                                                                        followBtn.TextLabel.Text = "Siguiendo"
                                                                                        authorStat2Num.Text = tostring(currentAuthorProfile.followers)
                                                                                    end
                                                                                end)
                                                                                
                                                                                local divAuthor = Frame(authorProfileScr, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), Colors.LightBg, 0)
                                                                                divAuthor.LayoutOrder = 5
                                                                                
                                                                                local authorWorksTitle = Label(authorProfileScr, "Obras del Autor", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), Colors.White, 18)
                                                                                authorWorksTitle.TextXAlignment = Enum.TextXAlignment.Left
                                                                                authorWorksTitle.LayoutOrder = 6
                                                                                
                                                                                local authorWorksContainer = Frame(authorProfileScr, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Colors.Background, 0)
                                                                                authorWorksContainer.LayoutOrder = 7
                                                                                authorWorksContainer.BackgroundTransparency = 1
                                                                                authorWorksContainer.AutomaticSize = Enum.AutomaticSize.Y
                                                                                local authorWorksList = Instance.new("UIListLayout")
                                                                                authorWorksList.Padding = UDim.new(0, 10)
                                                                                authorWorksList.Parent = authorWorksContainer
                                                                                
                                                                                -- ============= FUNCIONES NAVEGACIÓN =============
                                                                                
                                                                                local function ShowScreen(name)
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
                                                                                
                                                                                function GoHome()
                                                                                    ShowScreen("home")
                                                                                    HighlightNav("Inicio")
                                                                                    LoadStories()
                                                                                end
                                                                                
                                                                                function GoSearch()
                                                                                    ShowScreen("search")
                                                                                    HighlightNav("Buscar")
                                                                                    FilterSearchResults(nil)
                                                                                end
                                                                                
                                                                                function GoCreate()
                                                                                    ShowScreen("create")
                                                                                    editingStoryId = nil
                                                                                    HighlightNav("Publicar")
                                                                                end
                                                                                
                                                                                function GoWrite()
                                                                                    ShowScreen("write")
                                                                                end
                                                                                
                                                                                function GoProfile()
                                                                                    ShowScreen("profile")
                                                                                    HighlightNav("Perfil")
                                                                                    LoadUserStories()
                                                                                end
                                                                                
                                                                                function GoDetails(story)
                                                                                    currentStory = story
                                                                                    
                                                                                    detailsTitle.Text = story.title
                                                                                    authorName.Text = story.author
                                                                                    pcall(function()
                                                                                        authorImg.Image = Players:GetUserThumbnailAsync(story.authorId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                                                                                    end)
                                                                                    
                                                                                    local views = story.views or 0
                                                                                    statsLabel.Text = "👁️ " .. views .. "  •  " .. story.category .. "  •  " .. (story.status == "Completa" and "✅ Completa" or "⏳ En Emisión")
                                                                                    
                                                                                    tagText.Text = string.upper(story.category)
                                                                                    tagText.TextColor3 = Colors.Accent
                                                                                    
                                                                                    synBody.Text = story.synopsis ~= "" and story.synopsis or "El autor no ha añadido una descripción."
                                                                                    
                                                                                    coverGradient.BackgroundColor3 = Colors.Primary
                                                                                    
                                                                                    ShowScreen("details")
                                                                                end
                                                                                
                                                                                function GoReader(story)
                                                                                    currentStory = story
                                                                                    readerTitle.Text = story.title
                                                                                    readerText.Text = story.content or "..."
                                                                                    ShowScreen("reader")
                                                                                end
                                                                                
                                                                                -- ============= CARDS =============
                                                                                
                                                                                local function CreateCard(parent, story, isVertical)
                                                                                    local w, h = isVertical and 125 or 1, isVertical and 205 or 100
                                                                                    local card = Frame(parent, UDim2.new(isVertical and 0 or 1, isVertical and w or 0, 0, h), UDim2.new(0,0,0,0), Colors.CardBg, 8)
                                                                                    Stroke(card, Colors.Primary, 1)
                                                                                    
                                                                                    local coverH = isVertical and 135 or 100
                                                                                    local coverW = isVertical and w or 75
                                                                                    local cover = Frame(card, UDim2.new(0, coverW, 0, coverH), UDim2.new(0,0,0,0), Colors.Primary, 8)
                                                                                    if isVertical then
                                                                                        Round(cover, 8)
                                                                                    else
                                                                                        Round(cover, 8)
                                                                                    end
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
                                                                                        
                                                                                        local a = Label(info, "por " .. story.author, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 30), Colors.Gray, 12)
                                                                                        a.TextXAlignment = Enum.TextXAlignment.Left
                                                                                        
                                                                                        local s = Label(info, "👁️ " .. (story.views or 0) .. "  •  " .. story.category, UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 0, 52), Colors.DarkGray, 11)
                                                                                        s.TextXAlignment = Enum.TextXAlignment.Left
                                                                                    end
                                                                                    
                                                                                    local btn = Instance.new("TextButton")
                                                                                    btn.Size = UDim2.new(1, 0, 1, 0)
                                                                                    btn.BackgroundTransparency = 1
                                                                                    btn.Text = ""
                                                                                    btn.Parent = card
                                                                                    btn.MouseButton1Click:Connect(function() GoDetails(story) end)
                                                                                        
                                                                                        return card
                                                                                    end
                                                                                    
                                                                                    -- ============= FUNCIONES CARGA CON ANIMACIÓN =============
                                                                                    
                                                                                    function LoadStories()
                                                                                        for _, carousel in pairs(carousels) do
                                                                                            for _, c in ipairs(carousel:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                                                                                        end
                                                                                        local ok, stories = pcall(function() return GetAllStoriesFunction:InvokeServer() end)
                                                                                            if ok and stories then
                                                                                                for i = #stories, 1, -1 do
                                                                                                    local s = stories[i]
                                                                                                    if carousels[s.category] then CreateCard(carousels[s.category], s, true) end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                        
                                                                                        function FilterSearchResults(category)
                                                                                            -- Limpiar resultados anteriores
                                                                                            for _, c in ipairs(searchScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                                                                                            
                                                                                            -- Mostrar spinner ANTES de buscar
                                                                                            searchSpinner.Visible = true
                                                                                            startSearchSpinner()
                                                                                            resultCountLabel.Visible = false
                                                                                            
                                                                                            -- Esperar un frame para que se renderice el spinner
                                                                                            task.wait(0.1)
                                                                                            
                                                                                            local ok, stories
                                                                                            if searchBox.Text ~= "" then
                                                                                                ok, stories = pcall(function() return SearchStoriesFunction:InvokeServer(searchBox.Text) end)
                                                                                                else
                                                                                                    ok, stories = pcall(function() return GetAllStoriesFunction:InvokeServer() end)
                                                                                                    end
                                                                                                        
                                                                                                        -- Pequeño delay para que se vea la animación
                                                                                                        task.wait(0.3)
                                                                                                        
                                                                                                        if not ok then 
                                                                                                            stopSearchSpinner()
                                                                                                            searchSpinner.Visible = false
                                                                                                            resultCountLabel.Visible = true
                                                                                                            return 
                                                                                                        end
                                                                                                        
                                                                                                        local filtered = {}
                                                                                                        for _, s in ipairs(stories or {}) do
                                                                                                            if not category or category == "De Todo" or s.category == category then table.insert(filtered, s) end
                                                                                                        end
                                                                                                        
                                                                                                        resultCountLabel.Text = tostring(#filtered) .. " Resultados"
                                                                                                        for i = #filtered, 1, -1 do CreateCard(searchScroll, filtered[i], false) end
                                                                                                        
                                                                                                        -- Ocultar spinner
                                                                                                        stopSearchSpinner()
                                                                                                        searchSpinner.Visible = false
                                                                                                        resultCountLabel.Visible = true
                                                                                                    end
                                                                                                    
                                                                                                    function LoadUserStories()
                                                                                                        for _, c in ipairs(storiesContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                                                                                                        local ok, stories = pcall(function() return GetUserStoriesFunction:InvokeServer(player.UserId) end)
                                                                                                            profileStoriesCount.Text = tostring(stories and #stories or 0)
                                                                                                            if stories then
                                                                                                                for i = #stories, 1, -1 do CreateCard(storiesContainer, stories[i], false) end
                                                                                                            end
                                                                                                        end
                                                                                                        
                                                                                                        -- Búsqueda con debounce para mejor UX
                                                                                                        local searchDebounce = nil
                                                                                                        searchBox:GetPropertyChangedSignal("Text"):Connect(function() 
                                                                                                            if searchDebounce then
                                                                                                                searchDebounce:Cancel()
                                                                                                            end
                                                                                                            searchDebounce = task.delay(0.5, function()
                                                                                                                FilterSearchResults(selectedCatPill)
                                                                                                            end)
                                                                                                        end)
                                                                                                        
                                                                                                        -- ============= INICIAR =============
                                                                                                        wait(1)
                                                                                                        GoHome()
                                                                                                        print("[Client] Wattpad v4.0 (Roblox Style) Listo.")
