# Import file "travel_ui"
sketch = Framer.Importer.load("imported/travel_ui@2x")
sketch['ItemView'].destroy()

{modulate} = Utils
{abs} = Math

itemWidth = sketch['Item'].width
cardHeight = sketch['CardBackground'].height
gap = (Screen.width - itemWidth) / 2

page = new PageComponent
	width: Screen.width
	height: Screen.height
	scrollVertical: false
	originX: 0
	contentInset: 
		left: gap
		right: gap
	y: sketch['ItemList'].y
	parent: sketch['Menu']
	directionLock: true
	
thresholdToOpen = -page.y * 0.2
thresholdToClose = -page.y * 0.8

for number in [0...10]
	perspectiveLayer = new Layer
		width: itemWidth
		height: Screen.height
		backgroundColor: 'transparent'
		perspective: 1000
		parent: page.content
		x: (itemWidth + 22) * number
	
	item = sketch['Item'].copy()
	item.parent = perspectiveLayer
	item.opacity = 0.5
	item.x = 0
	item.draggable.enabled = false
	item.draggable.horizontal = false
	item.draggable.momentum = false

# 	item.draggable.constraints =
# 		y: -page.y
# 		height: Screen.height
	
	item.states.add
		open:
			y: -page.y
		closed:
			y: 0
	item.states.switchInstant("closed")
	item.states.animationOptions =
		curve: "spring(200, 20, 10)"
		
	item.draggable.on Events.DragEnd, do (item) -> () ->
		if item.y > thresholdToClose
			item.states.switch('closed')
		else if item.y < thresholdToOpen
			item.states.switch('open')
			
	boundRadius = 300
	item.draggable.on Events.DragMove, do (item) -> ({ offsetDirection }) ->
		print offsetDirection
		if item.y < -page.y
			item.draggable.speedY = 0
			item.y = -page.y
		else
			item.draggable.speedY = 1
# 		distance =
# 			y: Math.abs(item.y)
# 	
# 		item.draggable.speedY = 1 - Math.min(distance.y, boundRadius) / boundRadius
			
	item.on 'change:y', do (item) -> () ->
		[card] = item.childrenWithName('CardBackground')
		card.width = modulate(item.y, [0, -page.y], [itemWidth, Screen.width], true)
		card.height = modulate(item.y, [0, -page.y], [cardHeight, cardHeight * 1.3], true)
		card.centerX()
		card.clip = false
# 		print card.opacity

sketch['ItemList'].destroy()
	
startAtLayer = page.content.children[4]
startAtLayer.children[0].opacity = 1
startAtLayer.children[0].draggable.enabled = true
page.snapToPage(startAtLayer, false)

# why is `true` the default here?
page.clip = false
page.content.clip = false

calculateRotation = (distance) ->
# 	sign = if direction == 'right' then -1 else 1
# 	dist = distance % itemWidth
# 	print dist
	return 0

direction = 'left'
page.onScroll (event) -> 
	direction = event.offsetDirection if event.offsetDirection
# 	print event

page.onMove ->
	for { children: [thisLayer] } in page.content.children
		distance = abs(thisLayer.screenFrame.x - gap)
		thisLayer.opacity = modulate(distance, [0, itemWidth], [1, 0.3], true)
		thisLayer.rotationY = calculateRotation(distance, direction)
		
page.on "change:currentPage", ->
	for thisPage in page.content.children
		thisPage.children[0].draggable.enabled = thisPage == page.currentPage
		

	
	