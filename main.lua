local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local lib  = {}
lib.__index = lib

local styles = {
    dark = {
        mainFrame = {
            transparency = 0.05,
            color = Color3.fromRGB(25, 27.5, 30),
            size = UDim2.new(0.5, 0, 0.6, 0),
            corner = UDim.new(0.025, 0),
        },
        header = {
            transparency = 0.05,
            color = Color3.fromRGB(35, 38, 42),
            size = UDim2.new(1, 0, 0.075, 0),
            textColor = Color3.fromRGB(255, 255, 255),
            text = "Window",
            corner = UDim.new(0.25, 0),
            textSize = 20,
        },
    },
    light = {
        mainFrame = {
            transparency = 0.05,
            color = Color3.fromRGB(240, 240, 240),
            size = UDim2.new(0.5, 0, 0.6, 0),
            corner = UDim.new(0.025, 0),
        },
        header = {
            transparency = 0.05,
            color = Color3.fromRGB(220, 220, 220),
            size = UDim2.new(1, 0, 0.075, 0),
            textColor = Color3.fromRGB(20, 20, 20),
            text = "Window",
            corner = UDim.new(0.25, 0),
            textSize = 20,
        },
    },
}

local function ExecutorCall(name, ...)
    local args = {...}
    local code = "return " .. name .. "("
    for i = 1, #args do
        code = code .. "..." .. (i < #args and "," or "")
    end
    code = code .. ")"

    local chunk = loadstring
    local fn = chunk(code)
    if type(fn) ~= "function" then
        return false, nil
    end

    local ok, res = pcall(fn, table.unpack(args))
    return ok, res
end

local compat = {
    CoreGui = {
        success = false,
        result = nil
    },
    hui = {
        success = false,
        result = nil
    }
}
compat.hui.success, compat.hui.result = ExecutorCall("gethui")
local hui
if not compat.hui.success then
    compat.CoreGui.success, compat.CoreGui.result = pcall(function() return game:GetService("CoreGui") end)
    if compat.CoreGui.success then
        hui = Instance.new("Folder")
        hui.Name = "RobloxGui"
        hui.Parent = compat.CoreGui.result
    else
        hui = Player:WaitForChild("PlayerGui")
    end
else
    hui = compat.hui.result
end



function lib.new(style: string?, title: string?, textSize: number?)
    local self = setmetatable({}, lib)

    style = style or "dark"
    local theme = styles[style] or styles.dark
    if not theme then
        error("[lib] No styles defined!")
    end

    self.style = style
    self.theme = theme
    self.connections = {}
    self.children = {}

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ScreenGui"
    self.ScreenGui.DisplayOrder = 100
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = hui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.Size = theme.mainFrame.size
    mainFrame.BackgroundColor3 = theme.mainFrame.color
    mainFrame.BackgroundTransparency = theme.mainFrame.transparency
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = self.ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = theme.mainFrame.corner
    mainCorner.Parent = mainFrame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = theme.header.size
    header.Position = UDim2.fromScale(0, 0)
    header.BackgroundColor3 = theme.header.color
    header.BackgroundTransparency = theme.header.transparency
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.TopLeftRadius = theme.header.corner
    headerCorner.TopRightRadius = theme.header.corner
    headerCorner.BottomLeftRadius = UDim.new(0, 0)
    headerCorner.BottomRightRadius = UDim.new(0, 0)
    headerCorner.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.Position = UDim2.fromScale(0.03, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or theme.header.text
    titleLabel.TextColor3 = theme.header.textColor
    titleLabel.TextScaled = false
    titleLabel.TextSize = textSize or theme.header.textSize
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    self.Main = mainFrame
    self.Header = header
    self.Title = titleLabel

    table.insert(self.children, mainFrame)
    table.insert(self.children, header)
    table.insert(self.children, titleLabel)

    return self
end

function lib:SetDraggable(state: boolean)
    if self.dragConnection then
        self.dragConnection:Disconnect()
        self.dragConnection = nil
    end
    if self.dragBeginConnection then
        self.dragBeginConnection:Disconnect()
        self.dragBeginConnection = nil
    end
    if self.dragEndConnection then
        self.dragEndConnection:Disconnect()
        self.dragEndConnection = nil
    end

    self.draggable = state
    if not state then
        return
    end

    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart
    local startPos

    self.dragBeginConnection = self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end)

    self.dragEndConnection = self.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    self.dragConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        self.Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

function lib:Destroy()
    for _, conn in ipairs(self.connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.connections = {}


    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end


    self.children = {}
    self.style = nil

    setmetatable(self, nil)
end


return lib
