-- [[ GUHON MUSIC PLAYER V2.1 - FIXED RUNTIME FOR EXECUTOR ]]
-- โครงสร้างเดิมทั้งหมด 100% ห้ามแก้ชิ้นส่วนอื่น แก้ไขเฉพาะบั๊ก Sound Engine ที่ทำให้รันไม่ติด

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- 🔗 เชื่อมต่อ Remote Event เดิมของแมพ
local PlayerToolEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("PlayerToolEvent")

-- 🔊 สร้างระบบเสียงกดปุ่มเอกลักษณ์ (ตื้อดึง)
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://6895079853"
ClickSound.Volume = 0.6
ClickSound.Parent = SoundService

local function playClick()
	ClickSound:Play()
end

-- 🎵 สร้าง Sound Object สำหรับดึงสถานะเพลง (ย้ายไปไว้ใน Camera เพื่อแก้บั๊กดึงความดังไม่ขึ้นบน Executor)
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local ClientTrack = Camera:FindFirstChild("GuhonClientTrack") or Instance.new("Sound")
ClientTrack.Name = "GuhonClientTrack"
ClientTrack.Volume = 0 -- เปิดเสียงเป็น 0 เพื่อไม่ให้ซ้อนกับวิทยุในเกม
ClientTrack.Parent = Camera

local SavedSongs = {
	{Name = "muic", Id = "122903202007224"},
	{Name = "แม่จ๋า", Id = "8837194015"}
}
local currentEditingIndex = nil
local isPlaying = false
local totalDuration = 0

-------------------------------------------------------------------------------
-- 🏗️ โครงสร้าง UI และชุดตกแต่งลายเส้นเพิ่มมิติเดิมทั้งหมด (ห้ามแก้)
-------------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GuhonMusicUI_V2"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

-- 🟩 ปุ่มเปิด-ปิดแบบมีมิติเรืองแสง
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.Text = "🎵"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 0, 127)
ToggleBtn.TextSize = 22
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

local ToggleGlow = Instance.new("UIStroke")
ToggleGlow.Color = Color3.fromRGB(255, 0, 127)
ToggleGlow.Thickness = 1.5
ToggleGlow.Parent = ToggleBtn

-- ⬛ หน้าต่างหลัก (Main Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 320)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

MainFrame.Active = true
MainFrame.Draggable = true

-- ✨ เพิ่มเส้นขอบเรืองแสงรอบหน้าต่าง (Glow Stroke)
local FrameGlow = Instance.new("UIStroke")
FrameGlow.Color = Color3.fromRGB(255, 0, 127)
FrameGlow.Thickness = 1.2
FrameGlow.Transparency = 0.3
FrameGlow.Parent = MainFrame

-- 🌐 ลวดลายเส้นไอบอร์พื้นหลังตาราง - Cyber Grid Background
local PatternFrame = Instance.new("Frame")
PatternFrame.Size = UDim2.new(1.5, 0, 1.5, 0)
PatternFrame.Position = UDim2.new(-0.2, 0, -0.2, 0)
PatternFrame.BackgroundTransparency = 1
PatternFrame.Rotation = 15
PatternFrame.Parent = MainFrame

for i = 1, 15 do
	local GridLine = Instance.new("Frame")
	GridLine.Size = UDim2.new(1, 0, 0, 1)
	GridLine.Position = UDim2.new(0, 0, (i-1)/15, 0)
	GridLine.BackgroundColor3 = Color3.fromRGB(255, 0, 127)
	GridLine.BackgroundTransparency = 0.95
	GridLine.BorderSizePixel = 0
	GridLine.Parent = PatternFrame
end

-- ส่วนหัว (Header)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "PLAYER / VISUALIZER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.ZIndex = 2
Title.Parent = MainFrame

local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, -30, 0, 1)
Line.Position = UDim2.new(0, 15, 0, 50)
Line.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
Line.BorderSizePixel = 0
Line.ZIndex = 2
Line.Parent = MainFrame

-- แถบเมนูด้านล่าง (NavBar)
local NavBar = Instance.new("Frame")
NavBar.Size = UDim2.new(1, 0, 0, 50)
NavBar.Position = UDim2.new(0, 0, 1, -50)
NavBar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
NavBar.ZIndex = 2
NavBar.Parent = MainFrame
Instance.new("UICorner", NavBar).CornerRadius = UDim.new(0, 10)

local BtnHome = Instance.new("TextButton")
BtnHome.Size = UDim2.new(0, 60, 1, 0)
BtnHome.Position = UDim2.new(0, 20, 0, 0)
BtnHome.BackgroundTransparency = 1
BtnHome.Text = "🏠"
BtnHome.TextSize = 20
BtnHome.ZIndex = 3
BtnHome.Parent = NavBar

local BtnSavePage = Instance.new("TextButton")
BtnSavePage.Size = UDim2.new(0, 60, 1, 0)
BtnSavePage.Position = UDim2.new(0, 90, 0, 0)
BtnSavePage.BackgroundTransparency = 1
BtnSavePage.Text = "💾"
BtnSavePage.TextSize = 20
BtnSavePage.ZIndex = 3
BtnSavePage.Parent = NavBar

-------------------------------------------------------------------------------
-- 🏠 หน้าแรก: PLAYER / VISUALIZER (HomePage) - โครงสร้างเดิมทั้งหมด
-------------------------------------------------------------------------------
local HomePage = Instance.new("Frame")
HomePage.Size = UDim2.new(1, 0, 1, -100)
HomePage.Position = UDim2.new(0, 0, 0, 55)
HomePage.BackgroundTransparency = 1
HomePage.ZIndex = 2
HomePage.Parent = MainFrame

local MusicInput = Instance.new("TextBox")
MusicInput.Size = UDim2.new(0, 200, 0, 40)
MusicInput.Position = UDim2.new(0, 20, 0, 20)
MusicInput.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
MusicInput.Text = ""
MusicInput.PlaceholderText = "ENTER ID.."
MusicInput.TextColor3 = Color3.fromRGB(255, 255, 255)
MusicInput.TextSize = 14
MusicInput.ZIndex = 3
MusicInput.Parent = HomePage
Instance.new("UICorner", MusicInput).CornerRadius = UDim.new(0, 8)

local BtnPlay = Instance.new("TextButton")
BtnPlay.Size = UDim2.new(0, 50, 0, 50)
BtnPlay.Position = UDim2.new(0, 20, 0, 80)
BtnPlay.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
BtnPlay.Text = "▶️"
BtnPlay.TextSize = 18
BtnPlay.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnPlay.ZIndex = 3
BtnPlay.Parent = HomePage
Instance.new("UICorner", BtnPlay).CornerRadius = UDim.new(0, 25)

-- กล่องใส่แท่ง Visualizer คลื่นเสียง
local VisualizerContainer = Instance.new("Frame")
VisualizerContainer.Size = UDim2.new(0, 260, 0, 130)
VisualizerContainer.Position = UDim2.new(1, -280, 0, 10)
VisualizerContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
VisualizerContainer.ZIndex = 3
VisualizerContainer.Parent = HomePage
Instance.new("UICorner", VisualizerContainer).CornerRadius = UDim.new(0, 8)

-- สร้างแท่งคลื่นเสียงสีชมพูไล่เฉด (25 แท่ง)
local bars = {}
for i = 1, 25 do
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1/25, -2, 0.05, 0)
	bar.Position = UDim2.new((i-1)/25, 1, 1, 0)
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.fromHSV(0.95 - (i * 0.004), 0.85, 0.95)
	bar.ZIndex = 4
	bar.Parent = VisualizerContainer
	table.insert(bars, bar)
end

-- ข้อความแสดงเวลาเล่นเพลงแบบReal-Time
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(0, 150, 0, 20)
TimeLabel.Position = UDim2.new(1, -280, 0, 145)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"
TimeLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
TimeLabel.Font = Enum.Font.Code
TimeLabel.TextSize = 13
TimeLabel.ZIndex = 3
TimeLabel.Parent = HomePage

-------------------------------------------------------------------------------
-- 💾 หน้าสอง: รายการบันทึกเพลง (SavePage) - โครงสร้างเดิมทั้งหมด
-------------------------------------------------------------------------------
local SavePage = Instance.new("Frame")
SavePage.Size = UDim2.new(1, 0, 1, -100)
SavePage.Position = UDim2.new(0, 0, 0, 55)
SavePage.BackgroundTransparency = 1
SavePage.Visible = false
SavePage.ZIndex = 2
SavePage.Parent = MainFrame

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0, 160, 0, 35)
NameInput.Position = UDim2.new(0, 20, 0, 10)
NameInput.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
NameInput.Text = ""
NameInput.PlaceholderText = "NAME.."
NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NameInput.ZIndex = 3
NameInput.Parent = SavePage
Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)

local IdInput = Instance.new("TextBox")
IdInput.Size = UDim2.new(0, 160, 0, 35)
IdInput.Position = UDim2.new(0, 190, 0, 10)
IdInput.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
IdInput.Text = ""
IdInput.PlaceholderText = "ID.."
IdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
IdInput.ZIndex = 3
IdInput.Parent = SavePage
Instance.new("UICorner", IdInput).CornerRadius = UDim.new(0, 6)

local BtnAdd = Instance.new("TextButton")
BtnAdd.Size = UDim2.new(0, 80, 0, 35)
BtnAdd.Position = UDim2.new(0, 360, 0, 10)
BtnAdd.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
BtnAdd.Text = "ADD"
BtnAdd.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnAdd.ZIndex = 3
BtnAdd.Parent = SavePage
Instance.new("UICorner", BtnAdd).CornerRadius = UDim.new(0, 6)

local SongList = Instance.new("ScrollingFrame")
SongList.Size = UDim2.new(1, -40, 1, -60)
SongList.Position = UDim2.new(0, 20, 0, 55)
SongList.BackgroundTransparency = 1
SongList.CanvasSize = UDim2.new(0, 0, 0, 0)
SongList.ScrollBarThickness = 3
SongList.ZIndex = 3
SongList.Parent = SavePage

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.Parent = SongList

-------------------------------------------------------------------------------
-- ⚠️ หน้าต่างเด้งแก้ไขกลางจอ (Edit Pop-up) - โครงสร้างเดิมทั้งหมด
-------------------------------------------------------------------------------
local EditPopup = Instance.new("Frame")
EditPopup.Size = UDim2.new(0, 300, 0, 180)
EditPopup.Position = UDim2.new(0.5, -150, 0.5, -90)
EditPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
EditPopup.Visible = false
EditPopup.ZIndex = 5
EditPopup.Parent = MainFrame
Instance.new("UICorner", EditPopup).CornerRadius = UDim.new(0, 8)
local EditGlow = Instance.new("UIStroke")
EditGlow.Color = Color3.fromRGB(255, 0, 127)
EditGlow.Thickness = 1
EditGlow.Parent = EditPopup

local EditName = Instance.new("TextBox")
EditName.Size = UDim2.new(1, -40, 0, 35)
EditName.Position = UDim2.new(0, 20, 0, 20)
EditName.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
EditName.TextColor3 = Color3.fromRGB(255, 255, 255)
EditName.ZIndex = 6
EditName.Parent = EditPopup
Instance.new("UICorner", EditName).CornerRadius = UDim.new(0, 6)

local EditId = Instance.new("TextBox")
EditId.Size = UDim2.new(1, -40, 0, 35)
EditId.Position = UDim2.new(0, 20, 0, 65)
EditId.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
EditId.TextColor3 = Color3.fromRGB(255, 255, 255)
EditId.ZIndex = 6
EditId.Parent = EditPopup
Instance.new("UICorner", EditId).CornerRadius = UDim.new(0, 6)

local BtnSaveEdit = Instance.new("TextButton")
BtnSaveEdit.Size = UDim2.new(0, 110, 0, 35)
BtnSaveEdit.Position = UDim2.new(0, 20, 0, 120)
BtnSaveEdit.BackgroundColor3 = Color3.fromRGB(34, 112, 63)
BtnSaveEdit.Text = "SAVE"
BtnSaveEdit.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnSaveEdit.ZIndex = 6
BtnSaveEdit.Parent = EditPopup
Instance.new("UICorner", BtnSaveEdit).CornerRadius = UDim.new(0, 6)

local BtnCancelEdit = Instance.new("TextButton")
BtnCancelEdit.Size = UDim2.new(0, 110, 0, 35)
BtnCancelEdit.Position = UDim2.new(1, -130, 0, 120)
BtnCancelEdit.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
BtnCancelEdit.Text = "CANCEL"
BtnCancelEdit.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnCancelEdit.ZIndex = 6
BtnCancelEdit.Parent = EditPopup
Instance.new("UICorner", BtnCancelEdit).CornerRadius = UDim.new(0, 6)


-------------------------------------------------------------------------------
-- ⚙️ ฟังก์ชันคำนวณและแกนระบบ (แก้เฉพาะจุด Yield บั๊กรันไม่ติด)
-------------------------------------------------------------------------------

local function formatTime(seconds)
	if not seconds or seconds ~= seconds then return "00:00" end -- ดักกันค่า NaN บั๊กสคริปต์
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

local function fireMusic(songId)
	if songId then
		local args = {
			"ToolMusicText",
			tostring(songId),
			[4] = true
		}
		pcall(function() PlayerToolEvent:FireServer(unpack(args)) end)
	end
end

-- แก้ไขจุดที่ทำให้รันไม่ติด: โหลดข้อมูลแยก Thread ป้องกันสคริปต์ค้าง
local function startAudioTrack(songId)
	if songId and songId ~= "" and tonumber(songId) then
		ClientTrack:Stop()
		ClientTrack.SoundId = "rbxassetid://" .. songId
		totalDuration = 0
		
		-- ใช้ task.spawn แยกงานออกไป ไม่ให้ดึงขัดจังหวะการเปิด UI
		task.spawn(function()
			pcall(function()
				local assetInfo = MarketplaceService:GetProductInfo(tonumber(songId))
				if assetInfo and assetInfo.AssetTypeId == 3 then
					-- รอดักให้ Sound โหลดสำเร็จก่อนค่อยดึงข้อมูลจริงมาเซ็ต
					if not ClientTrack.IsLoaded then ClientTrack.Loaded:Wait() end
					totalDuration = ClientTrack.TimeLength
				end
			end)
		end)
		
		ClientTrack:Play()
	else
		ClientTrack:Stop()
		totalDuration = 0
	end
end

BtnPlay.MouseButton1Click:Connect(function()
	playClick()
	isPlaying = not isPlaying
	if isPlaying then
		BtnPlay.Text = "⏸️"
		startAudioTrack(MusicInput.Text)
		fireMusic(MusicInput.Text)
	else
		BtnPlay.Text = "▶️"
		startAudioTrack("")
		fireMusic("")
	end
end)

-- ลูปการทำงานแบบ Real-time ดึงระดับคลื่นความดังเสียงจริง
RunService.RenderStepped:Connect(function()
	if isPlaying and ClientTrack.IsPlaying then
		local currentTime = ClientTrack.TimePosition
		local maxTime = ClientTrack.TimeLength > 0 and ClientTrack.TimeLength or totalDuration
		TimeLabel.Text = formatTime(currentTime) .. " / " .. formatTime(maxTime)
		
		if maxTime > 0 and currentTime >= maxTime - 0.2 then
			ClientTrack.TimePosition = 0
			ClientTrack:Play()
		end
		
		-- ดึงค่าเบสจริงจากคลื่นเสียงมาประมวลผล (ตอนนี้ขยับได้แล้วเพราะย้ายไปไว้ที่ Camera)
		local loudness = ClientTrack.PlaybackLoudness
		for i, bar in pairs(bars) do
			local factor = math.sin((i / #bars) * math.pi) * (loudness / 320)
			local finalHeight = math.clamp(factor + (math.random(-8, 8) / 100), 0.08, 0.95)
			
			TweenService:Create(bar, TweenInfo.new(0.06, Enum.EasingStyle.Sine), {
				Size = UDim2.new(bar.Size.X.Scale, -2, finalHeight, 0)
			}):Play()
		end
	else
		TimeLabel.Text = "00:00 / " .. formatTime(ClientTrack.TimeLength)
		for _, bar in pairs(bars) do
			TweenService:Create(bar, TweenInfo.new(0.15), {
				Size = UDim2.new(bar.Size.X.Scale, -2, 0.05, 0)
			}):Play()
		end
	end
end)

-------------------------------------------------------------------------------
-- 📑 ระบบปุ่มควบคุมพื้นฐานเดิมทั้งหมด (โครงสร้างคงเดิม 100%)
-------------------------------------------------------------------------------

ToggleBtn.MouseButton1Click:Connect(function()
	playClick()
	MainFrame.Visible = not MainFrame.Visible
end)

local function showPage(page)
	playClick()
	HomePage.Visible = false
	SavePage.Visible = false
	page.Visible = true
	Title.Text = (page == HomePage) and "PLAYER / VISUALIZER" or "SAVE LIST"
end

BtnHome.MouseButton1Click:Connect(function() showPage(HomePage) end)
BtnSavePage.MouseButton1Click:Connect(function() showPage(SavePage) end)

local function refreshSaveList()
	for _, child in pairs(SongList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	SongList.CanvasSize = UDim2.new(0, 0, 0, #SavedSongs * 45)
	
	for index, data in ipairs(SavedSongs) do
		local Row = Instance.new("Frame")
		Row.Size = UDim2.new(1, -10, 0, 40)
		Row.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
		Row.ZIndex = 3
		Row.Parent = SongList
		Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 5)
		
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(0.5, 0, 1, 0)
		TextLabel.Position = UDim2.new(0, 10, 0, 0)
		TextLabel.OriginalSize = Row.Size -- ยึดไว้เฉยๆ
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = data.Name
		TextLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
		TextLabel.Font = Enum.Font.Gotham
		TextLabel.TextSize = 13
		TextLabel.ZIndex = 4
		TextLabel.Parent = Row
		
		local PBtn = Instance.new("TextButton")
		PBtn.Size = UDim2.new(0, 30, 0, 30)
		PBtn.Position = UDim2.new(1, -110, 0.5, -15)
		PBtn.BackgroundTransparency = 1
		PBtn.Text = "▶️"
		PBtn.TextSize = 15
		PBtn.ZIndex = 4
		PBtn.Parent = Row
		
		PBtn.MouseButton1Click:Connect(function()
			playClick()
			MusicInput.Text = data.Id
			isPlaying = true
			BtnPlay.Text = "⏸️"
			startAudioTrack(data.Id)
			fireMusic(data.Id)
			showPage(HomePage)
		end)
		
		local EBtn = Instance.new("TextButton")
		EBtn.Size = UDim2.new(0, 30, 0, 30)
		EBtn.Position = UDim2.new(1, -75, 0.5, -15)
		EBtn.BackgroundTransparency = 1
		EBtn.Text = "📝"
		EBtn.TextSize = 15
		EBtn.ZIndex = 4
		EBtn.Parent = Row
		
		EBtn.MouseButton1Click:Connect(function()
			playClick()
			currentEditingIndex = index
			EditName.Text = data.Name
			EditId.Text = data.Id
			EditPopup.Visible = true
		end)
		
		local DBtn = Instance.new("TextButton")
		DBtn.Size = UDim2.new(0, 30, 0, 30)
		DBtn.Position = UDim2.new(1, -40, 0.5, -15)
		DBtn.BackgroundTransparency = 1
		DBtn.Text = "🗑️"
		DBtn.TextSize = 15
		DBtn.ZIndex = 4
		DBtn.Parent = Row
		
		DBtn.MouseButton1Click:Connect(function()
			playClick()
			table.remove(SavedSongs, index)
			refreshSaveList()
		end)
	end
end

BtnAdd.MouseButton1Click:Connect(function()
	if NameInput.Text ~= "" and IdInput.Text ~= "" then
		playClick()
		table.insert(SavedSongs, {Name = NameInput.Text, Id = IdInput.Text})
		NameInput.Text = ""
		IdInput.Text = ""
		refreshSaveList()
	end
end)

BtnSaveEdit.MouseButton1Click:Connect(function()
	if currentEditingIndex and EditName.Text ~= "" and EditId.Text ~= "" then
		playClick()
		SavedSongs[currentEditingIndex].Name = EditName.Text
		SavedSongs[currentEditingIndex].Id = EditId.Text
		EditPopup.Visible = false
		refreshSaveList()
	end
end)

BtnCancelEdit.MouseButton1Click:Connect(function()
	playClick()
	EditPopup.Visible = false
end)

refreshSaveList()
