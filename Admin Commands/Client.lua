print('Loading Red Vice Admin LocalScript')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local event = ReplicatedStorage:WaitForChild('AdminEvent')
local gui = Instance.new('ScreenGui', script.Parent)
gui.Name = 'RV Admin Gui'

local Time = .2

local BLACK = Color3.new(27/255, 42/255, 53/255)
local WHITE = Color3.new(1, 1, 1)

--Types of GUIs to create: Message, Hint, UnorderedList

event.OnClientEvent:connect(function(Type, Content)
	print('Fired a ' .. Type)
	if Type == 'Message' then
		local Message = Content[2]
		local Sender = Content[1]

		local Frame = Instance.new('Frame', gui)
			Frame.BackgroundColor3 = BLACK
			Frame.BackgroundTransparency = .2
			Frame.BorderSizePixel = 0
			Frame.Position = UDim2.new(-.3, 0, .2, 0)
			Frame.Size = UDim2.new(.4, 0, .6, 0)
			Frame.ClipsDescendants = true

		local Top = Instance.new('TextLabel', Frame)
			Top.BackgroundTransparency = 1
			Top.BorderSizePixel = 0
			Top.Size = UDim2.new(1, 0, 0, 30)
			Top.TextColor3 = WHITE
			Top.ZIndex = 2
			Top.Font = 'SourceSansBold'
			Top.FontSize = 'Size24'
			Top.Text = Sender

		local Bottom = Instance.new('TextLabel', Frame)
			Bottom.BackgroundTransparency = 1
			Bottom.BorderSizePixel = 0
			Bottom.Size = UDim2.new(1, -20, 1, -40)
			Bottom.Position = UDim2.new(0, 10, 0, 40)
			Bottom.TextColor3 = WHITE
			Bottom.ZIndex = 2
			Bottom.Font = 'SourceSans'
			Bottom.FontSize = 'Size24'
			Bottom.Text = Message
			Bottom.TextWrapped = true
			Bottom.TextXAlignment = 'Left'
			Bottom.TextYAlignment = 'Top'

		Frame:TweenPosition(UDim2.new(.3, 0, .2, 0), 'Out', 'Quad', Time)
		wait(Time)
		wait(Message:len() / 3 + 2)
		Frame:TweenPosition(UDim2.new(1, 0, .2, 0), 'Out', 'Quad', Time)
		wait(Time)
		Frame:Destroy()
	elseif Type == 'Hint' then
		local Hint = Instance.new('TextLabel', gui)
		Hint.BackgroundColor3 = BLACK
			Hint.BackgroundTransparency = .2
			Hint.BorderSizePixel = 0
			Hint.Position = UDim2.new(0, 0, 0, -30)
			Hint.Size = UDim2.new(1, 0, 0, 30)
			Hint.FontSize = 'Size14'
			Hint.Text = Content
			Hint.TextColor3 = WHITE

		Hint:TweenPosition(UDim2.new(0, 0, 0, 0), 'Out', 'Quad', Time)
		wait(Time)
		wait(Content:len() / 3 + 1)
		Hint:TweenPosition(UDim2.new(0, 0, 0, -30), 'Out', 'Quad', Time)
		wait(Time)
		Hint:Destroy()
	elseif Type == 'UnorderedList' then
		local Frame = Instance.new('ScrollingFrame', gui)
			Frame.BackgroundColor3 = BLCK
			Frame.BackgroundTransparency = .2
			Frame.BorderSizePixel = 0
			Frame.Position = UDim2.new(-.3, 0, .2, 0)
			Frame.Size = UDim2.new(.4, 0, .6, 0)
			Frame.CanvasSize = #Content * 60 / Frame.AbsoluteWindowSize.Y

		for i,v in pairs(Content) do
			local Element = Instance.new('TextLabel', Frame)
			Element.Position = UDim2.new(0, 10, 0, (i - 1)*60 + 5)
			Element.Size = UDim2.new(1, -32, 0, 50)
			Element.ZIndex = 2
			Element.ClipsDescendants = true
			Element.FontSize = 'Size18'
			Element.Text = v
			Element.TextWrapped = true
		end

		local Exit = Instance.new('TextButton', gui)
			Exit.BackgroundTransparency = 1
			Exit.BorderSizePixel = 0
			Exit.ClipsDescendants = true
			Exit.Position = UDim2.new(.7, -12, 0.2, -16)
			Exit.Size = UDim2.new(0, 12, 0, 12)
			Exit.FontSize = 'Size18'
			Exit.Text = 'X'
			Exit.Visible = false

		Frame:TweenPosition(UDim2.new(.3, 0, .2, 0), 'Out', 'Quad', Time)
		wait(Time)
		Exit.Visible = true
		Exit.MouseButton1Click:connect(function()
			Frame:TweenPosition(UDim2.new(1, 0, .2, 0), 'Out', 'Quad', Time)
			wait(Time)
			Frame:Destroy()
		end)
	end
end)

print('Red Vice Admin LocalScript Loaded')