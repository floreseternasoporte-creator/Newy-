-- SERVER SCRIPT - Wattpad Clone v4.0 CON ACTUALIZACIONES EN TIEMPO REAL
-- Colocar en ServerScriptService
 
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- DataStores
local StoriesDataStore = DataStoreService:GetDataStore("StoriesData_v4")
local AuthorsDataStore = DataStoreService:GetDataStore("Authors_v4")
 
-- RemoteEvents y RemoteFunctions
local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "WattpadRemotes"
RemoteFolder.Parent = ReplicatedStorage
 
-- Historias
local PublishStoryEvent = Instance.new("RemoteEvent")
PublishStoryEvent.Name = "PublishStory"
PublishStoryEvent.Parent = RemoteFolder
 
local UpdateStoryEvent = Instance.new("RemoteEvent")
UpdateStoryEvent.Name = "UpdateStory"
UpdateStoryEvent.Parent = RemoteFolder
 
local GetAllStoriesFunction = Instance.new("RemoteFunction")
GetAllStoriesFunction.Name = "GetAllStories"
GetAllStoriesFunction.Parent = RemoteFolder
 
local GetStoriesByCategoryFunction = Instance.new("RemoteFunction")
GetStoriesByCategoryFunction.Name = "GetStoriesByCategory"
GetStoriesByCategoryFunction.Parent = RemoteFolder
 
local GetUserStoriesFunction = Instance.new("RemoteFunction")
GetUserStoriesFunction.Name = "GetUserStories"
GetUserStoriesFunction.Parent = RemoteFolder
 
local SearchStoriesFunction = Instance.new("RemoteFunction")
SearchStoriesFunction.Name = "SearchStories"
SearchStoriesFunction.Parent = RemoteFolder
 
local GetStoryByIdFunction = Instance.new("RemoteFunction")
GetStoryByIdFunction.Name = "GetStoryById"
GetStoryByIdFunction.Parent = RemoteFolder
 
-- Autores y Seguidores
local GetAuthorProfileFunction = Instance.new("RemoteFunction")
GetAuthorProfileFunction.Name = "GetAuthorProfile"
GetAuthorProfileFunction.Parent = RemoteFolder
 
local FollowAuthorEvent = Instance.new("RemoteEvent")
FollowAuthorEvent.Name = "FollowAuthor"
FollowAuthorEvent.Parent = RemoteFolder
 
local UnfollowAuthorEvent = Instance.new("RemoteEvent")
UnfollowAuthorEvent.Name = "UnfollowAuthor"
UnfollowAuthorEvent.Parent = RemoteFolder
 
local SearchAuthorsFunction = Instance.new("RemoteFunction")
SearchAuthorsFunction.Name = "SearchAuthors"
SearchAuthorsFunction.Parent = RemoteFolder
 
local GetAllAuthorsFunction = Instance.new("RemoteFunction")
GetAllAuthorsFunction.Name = "GetAllAuthors"
GetAllAuthorsFunction.Parent = RemoteFolder
 
-- ⭐ NUEVOS EVENTOS PARA TIEMPO REAL
local StoryUpdatedEvent = Instance.new("RemoteEvent")
StoryUpdatedEvent.Name = "StoryUpdated"
StoryUpdatedEvent.Parent = RemoteFolder
 
local AuthorUpdatedEvent = Instance.new("RemoteEvent")
AuthorUpdatedEvent.Name = "AuthorUpdated"
AuthorUpdatedEvent.Parent = RemoteFolder
 
local IncrementViewEvent = Instance.new("RemoteEvent")
IncrementViewEvent.Name = "IncrementView"
IncrementViewEvent.Parent = RemoteFolder
 
-- Tablas en memoria
local AllStories = {}
local AllAuthors = {}
local StoryIdCounter = 0
 
-- Categorías
local Categories = {
"Romance", "Fantasía", "Ciencia Ficción", "Misterio", 
"Terror", "Aventura", "Drama", "Comedia", 
"Fanfic", "Poesía", "Acción", "Thriller"
}
 
-- ============= FUNCIONES AUXILIARES =============
 
local function GenerateStoryId()
    StoryIdCounter = StoryIdCounter + 1
    return "story_" .. tostring(os.time()) .. "_" .. tostring(StoryIdCounter)
end
 
-- ⭐ Notificar a todos los clientes sobre cambios
local function BroadcastStoryUpdate(storyId)
    for _, player in ipairs(Players:GetPlayers()) do
        StoryUpdatedEvent:FireClient(player, storyId)
    end
end
 
local function BroadcastAuthorUpdate(userId)
    for _, player in ipairs(Players:GetPlayers()) do
        AuthorUpdatedEvent:FireClient(player, userId)
    end
end
 
-- ============= CARGAR Y GUARDAR DATOS =============
 
local function LoadAllStories()
    local success, result = pcall(function()
        return StoriesDataStore:GetAsync("AllStoriesData")
    end)
    
    if success and result then
        AllStories = result.stories or {}
        StoryIdCounter = result.counter or 0
        print("[Server] ✅ Historias cargadas:", #AllStories)
    else
        AllStories = {}
        StoryIdCounter = 0
        print("[Server] 📝 Iniciando sistema nuevo de historias")
    end
end
 
local function SaveAllStories()
    local success, errorMsg = pcall(function()
        StoriesDataStore:SetAsync("AllStoriesData", {
        stories = AllStories,
        counter = StoryIdCounter
        })
    end)
    
    if success then
        print("[Server] ✅ Historias guardadas")
    else
        warn("[Server] ❌ Error al guardar historias:", errorMsg)
    end
end
 
local function LoadAllAuthors()
    local success, result = pcall(function()
        return AuthorsDataStore:GetAsync("AllAuthorsData")
    end)
    
    if success and result then
        AllAuthors = result or {}
        print("[Server] ✅ Autores cargados")
    else
        AllAuthors = {}
        print("[Server] 📝 Iniciando sistema nuevo de autores")
    end
end
 
local function SaveAllAuthors()
    local success, errorMsg = pcall(function()
        AuthorsDataStore:SetAsync("AllAuthorsData", AllAuthors)
    end)
    
    if success then
        print("[Server] ✅ Autores guardados")
    else
        warn("[Server] ❌ Error al guardar autores:", errorMsg)
    end
end
 
local function RegisterAuthor(player)
    local userId = tostring(player.UserId)
    
    if not AllAuthors[userId] then
        AllAuthors[userId] = {
        userId = player.UserId,
        name = player.Name,
        displayName = player.DisplayName,
        followers = {},
        following = {},
        storiesCount = 0,
        joinDate = os.time()
        }
        SaveAllAuthors()
        print("[Server] ✅ Autor registrado:", player.Name)
    end
    
    return AllAuthors[userId]
end
 
local function GetAuthorData(userId)
    return AllAuthors[tostring(userId)]
end
 
local function UpdateAuthorStoriesCount(userId)
    local userIdStr = tostring(userId)
    if AllAuthors[userIdStr] then
        local count = 0
        for _, story in ipairs(AllStories) do
            if story.authorId == userId then
                count = count + 1
            end
        end
        AllAuthors[userIdStr].storiesCount = count
        SaveAllAuthors()
        BroadcastAuthorUpdate(userId)
    end
end
 
-- ============= EVENTOS DE HISTORIAS =============
 
PublishStoryEvent.OnServerEvent:Connect(function(player, storyData)
    if not storyData or not storyData.title or storyData.title == "" then
        warn("[Server] ❌ Datos inválidos")
        return
    end
    
    RegisterAuthor(player)
    
    local newStory = {
    id = GenerateStoryId(),
    title = storyData.title,
    synopsis = storyData.synopsis or "",
    content = storyData.content or "",
    category = storyData.category or "Sin categoría",
    status = storyData.status or "En progreso",
    characters = storyData.characters or {},
    author = player.Name,
    authorDisplayName = player.DisplayName,
    authorId = player.UserId,
    publishDate = os.time(),
    lastUpdate = os.time(),
    views = 0,
    reads = 0
    }
    
    table.insert(AllStories, newStory)
    SaveAllStories()
    UpdateAuthorStoriesCount(player.UserId)
    
    -- ⭐ Notificar a todos
    BroadcastStoryUpdate(newStory.id)
    
    print("[Server] ✅ Historia publicada:", newStory.title, "por", player.Name)
end)
 
UpdateStoryEvent.OnServerEvent:Connect(function(player, storyId, updatedData)
    for i, story in ipairs(AllStories) do
        if story.id == storyId and story.authorId == player.UserId then
            if updatedData.title then story.title = updatedData.title end
            if updatedData.synopsis then story.synopsis = updatedData.synopsis end
            if updatedData.content then story.content = updatedData.content end
            if updatedData.category then story.category = updatedData.category end
            if updatedData.status then story.status = updatedData.status end
            if updatedData.characters then story.characters = updatedData.characters end
            
            story.lastUpdate = os.time()
            SaveAllStories()
            
            -- ⭐ Notificar a todos
            BroadcastStoryUpdate(storyId)
            
            print("[Server] ✅ Historia actualizada:", story.title)
            return
        end
    end
    
    warn("[Server] ❌ Historia no encontrada o sin permisos")
end)
 
-- ⭐ NUEVO: Incrementar vistas en tiempo real
IncrementViewEvent.OnServerEvent:Connect(function(player, storyId)
    for i, story in ipairs(AllStories) do
        if story.id == storyId then
            story.views = (story.views or 0) + 1
            SaveAllStories()
            
            -- Notificar a todos los clientes
            BroadcastStoryUpdate(storyId)
            
            print("[Server] 👁️ Vista añadida a:", story.title, "Total:", story.views)
            return
        end
    end
end)
 
-- ============= FUNCIONES DE HISTORIAS =============
 
GetAllStoriesFunction.OnServerInvoke = function(player)
    return AllStories
end
 
GetStoriesByCategoryFunction.OnServerInvoke = function(player, category)
    local categoryStories = {}
    for _, story in ipairs(AllStories) do
        if story.category == category then
            table.insert(categoryStories, story)
        end
    end
    return categoryStories
end
 
GetUserStoriesFunction.OnServerInvoke = function(player, targetUserId)
    local userStories = {}
    for _, story in ipairs(AllStories) do
        if story.authorId == targetUserId then
            table.insert(userStories, story)
        end
    end
    return userStories
end
 
SearchStoriesFunction.OnServerInvoke = function(player, searchQuery)
    if not searchQuery or searchQuery == "" then
        return AllStories
    end
    
    local results = {}
    local lowerQuery = string.lower(searchQuery)
    
    for _, story in ipairs(AllStories) do
        local lowerTitle = string.lower(story.title)
        local lowerAuthor = string.lower(story.author)
        local lowerCategory = string.lower(story.category)
        
        if string.find(lowerTitle, lowerQuery) or 
            string.find(lowerAuthor, lowerQuery) or 
            string.find(lowerCategory, lowerQuery) then
            table.insert(results, story)
        end
    end
    
    return results
end
 
GetStoryByIdFunction.OnServerInvoke = function(player, storyId)
    for _, story in ipairs(AllStories) do
        if story.id == storyId then
            return story
        end
    end
    return nil
end
 
-- ============= FUNCIONES DE AUTORES =============
 
GetAuthorProfileFunction.OnServerInvoke = function(player, targetUserId)
    local authorData = GetAuthorData(targetUserId)
    
    if not authorData then
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if targetPlayer then
            RegisterAuthor(targetPlayer)
            authorData = GetAuthorData(targetUserId)
        else
            return nil
        end
    end
    
    local isFollowing = false
    if player and AllAuthors[tostring(player.UserId)] then
        for _, followedId in ipairs(AllAuthors[tostring(player.UserId)].following) do
            if followedId == targetUserId then
                isFollowing = true
                break
            end
        end
    end
    
    return {
    userId = authorData.userId,
    name = authorData.name,
    displayName = authorData.displayName,
    followers = #authorData.followers,
    following = #authorData.following,
    storiesCount = authorData.storiesCount,
    isFollowing = isFollowing,
    joinDate = authorData.joinDate
    }
end
 
FollowAuthorEvent.OnServerEvent:Connect(function(player, targetUserId)
    local myUserId = tostring(player.UserId)
    local targetUserIdStr = tostring(targetUserId)
    
    if player.UserId == targetUserId then
        warn("[Server] ❌ No puedes seguirte a ti mismo")
        return
    end
    
    RegisterAuthor(player)
    
    local targetAuthor = GetAuthorData(targetUserId)
    if not targetAuthor then
        warn("[Server] ❌ Autor objetivo no encontrado")
        return
    end
    
    -- Verificar si ya sigue
    for _, id in ipairs(AllAuthors[myUserId].following) do
        if id == targetUserId then
            warn("[Server] ⚠️ Ya sigues a este autor")
            return
        end
    end
    
    table.insert(AllAuthors[myUserId].following, targetUserId)
    table.insert(AllAuthors[targetUserIdStr].followers, player.UserId)
    
    SaveAllAuthors()
    
    -- ⭐ Notificar a todos
    BroadcastAuthorUpdate(player.UserId)
    BroadcastAuthorUpdate(targetUserId)
    
    print("[Server] ✅", player.Name, "ahora sigue a", AllAuthors[targetUserIdStr].name)
end)
 
UnfollowAuthorEvent.OnServerEvent:Connect(function(player, targetUserId)
    local myUserId = tostring(player.UserId)
    local targetUserIdStr = tostring(targetUserId)
    
    if not AllAuthors[myUserId] or not AllAuthors[targetUserIdStr] then
        warn("[Server] ❌ Datos de autor no encontrados")
        return
    end
    
    for i, id in ipairs(AllAuthors[myUserId].following) do
        if id == targetUserId then
            table.remove(AllAuthors[myUserId].following, i)
            break
        end
    end
    
    for i, id in ipairs(AllAuthors[targetUserIdStr].followers) do
        if id == player.UserId then
            table.remove(AllAuthors[targetUserIdStr].followers, i)
            break
        end
    end
    
    SaveAllAuthors()
    
    -- ⭐ Notificar a todos
    BroadcastAuthorUpdate(player.UserId)
    BroadcastAuthorUpdate(targetUserId)
    
    print("[Server] ✅", player.Name, "dejó de seguir a", AllAuthors[targetUserIdStr].name)
end)
 
SearchAuthorsFunction.OnServerInvoke = function(player, searchQuery)
    if not searchQuery or searchQuery == "" then
        local allAuthorsList = {}
        for userId, authorData in pairs(AllAuthors) do
            table.insert(allAuthorsList, {
            userId = authorData.userId,
            name = authorData.name,
            displayName = authorData.displayName,
            followers = #authorData.followers,
            following = #authorData.following,
            storiesCount = authorData.storiesCount
            })
        end
        return allAuthorsList
    end
    
    local results = {}
    local lowerQuery = string.lower(searchQuery)
    
    for userId, authorData in pairs(AllAuthors) do
        local lowerName = string.lower(authorData.name)
        local lowerDisplayName = string.lower(authorData.displayName)
        
        if string.find(lowerName, lowerQuery) or string.find(lowerDisplayName, lowerQuery) then
            table.insert(results, {
            userId = authorData.userId,
            name = authorData.name,
            displayName = authorData.displayName,
            followers = #authorData.followers,
            following = #authorData.following,
            storiesCount = authorData.storiesCount
            })
        end
    end
    
    return results
end
 
GetAllAuthorsFunction.OnServerInvoke = function(player)
    local allAuthorsList = {}
    for userId, authorData in pairs(AllAuthors) do
        table.insert(allAuthorsList, {
        userId = authorData.userId,
        name = authorData.name,
        displayName = authorData.displayName,
        followers = #authorData.followers,
        following = #authorData.following,
        storiesCount = authorData.storiesCount
        })
    end
    return allAuthorsList
end
 
-- ============= REGISTRO AUTOMÁTICO AL ENTRAR =============
 
Players.PlayerAdded:Connect(function(player)
    RegisterAuthor(player)
end)
 
-- ============= INICIALIZACIÓN =============
 
LoadAllStories()
LoadAllAuthors()
 
-- Auto-guardado cada 3 minutos
spawn(function()
    while true do
        wait(180)
        SaveAllStories()
        SaveAllAuthors()
        print("[Server] 💾 Auto-guardado completado")
    end
end)
 
print("[Server] ✅ Sistema Wattpad v4.0 CON TIEMPO REAL iniciado")
print("[Server] 📚 Historias cargadas:", #AllStories)
print("[Server] 👥 Autores registrados:", #vim.tbl_keys(AllAuthors))
