sketch = Framer.Importer.load('imported/travel_ui@2x')
sketch['ItemView'].destroy()
sketch['StatusBar'].index = 200

Framer.Extras.Hints.disable() # i wish i could disable it only for "tap on draggable"

{modulate} = Utils
{abs, floor, min, max} = Math

itemWidth = sketch['Item'].width
cardHeight = sketch['CardBackground'].height
commentBaseY = sketch['Comment'].y
sideGap = (Screen.width - itemWidth) / 2
listGap = 30
inactiveItemOpacity = 0.5

page = new PageComponent
	index: 100
	width: Screen.width
	height: Screen.height
	scrollVertical: false
	originX: 0
	contentInset: 
		left: sideGap
		right: sideGap
	y: sketch['ItemList'].y
	parent: sketch['Menu']
	directionLock: true

listY = -page.y
	
thresholdToOpen = listY * 0.2
thresholdToClose = listY * 0.8

for number in [0...10]
	perspectiveLayer = new Layer
		perspective: 2000
		width: itemWidth
		height: Screen.height
		backgroundColor: 'transparent'
		parent: page.content
		x: (itemWidth + listGap) * number
	
	item = sketch['Item'].copy()
	item.parent = perspectiveLayer
	item.opacity = inactiveItemOpacity
	item.x = 0
	item.index = 50
	item.draggable.enabled = false
	item.draggable.horizontal = false
	item.draggable.momentum = false
	
	item.states.add
		open:
			y: listY
		closed:
			y: 0
	item.states.switchInstant('closed')
	item.states.animationOptions =
		curve: "spring(200, 20, 10)"
		
	item.draggable.on Events.DragStart, () ->
		page.speedX = 0
			
	item.draggable.on Events.DragMove, do (item) -> () ->
		distance = abs(item.y)
		radius = if item.y < 0 then 300 else 100
		item.draggable.speedY = 1 - min(distance, radius) / radius
		
	item.draggable.on Events.DragEnd, do (item) -> ({ offsetDirection }) ->
		item.draggable.speedY = 1
		
		if offsetDirection == 'down'
			item.states.switch('closed')
			page.speedX = 1
		else if offsetDirection == 'up'
			item.states.switch('open')
			
	item.on 'change:y', do (item) -> () ->
		[card] = item.childrenWithName('CardBackground')
		[comment] = item.childrenWithName('Comment')
		[cardContent] = item.childrenWithName('CardContent')
		
		card.width =
			modulate(item.y, [0, listY], [itemWidth, Screen.width * 1.2], true)
		card.height =
			modulate(item.y, [0, listY], [cardHeight, cardHeight * 1.2], true)
		card.centerX()

		comment.y =
			modulate(item.y, [0, listY], [commentBaseY, commentBaseY + 120], true)
		comment.scale =
			modulate(item.y, [0, listY], [1, 1.2], true)
		
		cardContent.y =
			modulate(item.y, [0, listY], [0, 50], true)
		cardContent.scale =
			modulate(item.y, [0, listY], [1, 1.2], true)
			
		for thisPage in page.content.children
			if thisPage isnt page.currentPage
				thisPage.children[0].opacity =
					modulate(item.y, [0, listY * 0.7], [inactiveItemOpacity, 0], true)

sketch['ItemList'].destroy()
	
startAtLayer = page.content.children[4]
startAtLayer.children[0].opacity = 1
startAtLayer.index = 60
startAtLayer.children[0].draggable.enabled = true
page.snapToPage(startAtLayer, false)

# why is `true` the default here?
page.clip = false
page.content.clip = false

pageDragDirection = 'left'
pageDragDistance = 0
page.onScroll (event) -> 
	pageDragDistance = abs(event.offset.x) if event.offset
	pageDragDirection = event.offsetDirection if event.offsetDirection
	
	for { children: [thisLayer] } in page.content.children
		facing = if pageDragDirection == 'right' then -1 else 1
		thisLayer.rotationY = modulate(pageDragDistance, [0, 200], [0, 10], true) * facing
	
calculateRotation = ->
page.onMove ->
	for { children: [thisLayer] } in page.content.children
		distance = abs(thisLayer.screenFrame.x - sideGap)
		thisLayer.opacity =
			modulate(distance, [0, itemWidth], [1, inactiveItemOpacity], true)
		
page.on 'change:currentPage', ->
	for thisPage in page.content.children
		isActive = thisPage == page.currentPage
		thisPage.children[0].draggable.enabled = isActive
		thisPage.index = if isActive then 60 else 50
	
page.on Events.ScrollStart, ->
	for { children: [thisLayer] } in page.content.children
		thisLayer.draggable.speedY = 0
		
page.on Events.Scroll, ->
	
page.on Events.ScrollEnd, ->
	pageDragDistance = 0
	for { children: [thisLayer] } in page.content.children
		thisLayer.draggable.speedY = 1
		thisLayer.animate
			properties:
				rotationY: 0
	
	