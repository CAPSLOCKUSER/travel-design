# Import file "travel_ui" (sizes and positions are scaled 1:2)
sketch4 = Framer.Importer.load("imported/travel_ui@2x")
sketch = Framer.Importer.load('imported/travel_ui@2x')
sketch['ItemView'].destroy()

Framer.Extras.Hints.disable() # i wish i could disable it only for "tap on draggable"

{modulate} = Utils
{abs, floor, min, max} = Math

createModulate = (value) -> (fromA, fromB) -> (toA, toB) ->
	modulate(value, [fromA, fromB], [toA, toB], true)
	
INDEX =
	STATUS_BAR: 200
	ACTIVE_CARD: 60
	INACTIVE_CARD: 50
	PAGE: 100

itemWidth = sketch['Item'].width
cardHeight = sketch['CardBackground'].height
commentBaseY = sketch['Comment'].y
sideGap = (Screen.width - itemWidth) / 2
listGap = 30
inactiveItemOpacity = 0.5
listY = -sketch['ItemList'].y
searchFieldWidth = sketch['SearchField'].width

page = new PageComponent
	index: INDEX.PAGE
	width: Screen.width
	height: Screen.height
	scrollVertical: false
	originX: 0
	contentInset: 
		left: sideGap
		right: sideGap
	y: sketch['ItemList'].y
	parent: sketch['Menu']

# page.animateOptions = page.animate.options
# 
# page.animate
# 	options:
# 		curve: "spring(631, 10, 14)"

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
	item.index = INDEX.INACTIVE_CARD
	item.draggable.enabled = false
	item.draggable.horizontal = false
	item.draggable.momentum = false
	
	item.states =
		open:
			y: listY
		closed:
			y: 0
	item.animate 'closed', instant: true
	item.states.animationOptions =
		curve: 'spring(200, 20, 10)'
		
	item.draggable.on Events.DragStart, () ->
		page.content.draggable = false
			
	item.draggable.on Events.DragMove, do (item) -> () ->
		distance = abs(item.y)
		radius = if item.y < 0 then 300 else 100
		item.draggable.speedY = 1 - min(distance, radius) / radius
		
	item.draggable.on Events.DragEnd, do (item) -> ({ offsetDirection }) ->
		item.draggable.speedY = 1
		
		if offsetDirection == 'down'
			item.animate 'closed'
			page.content.draggable = true
		else if offsetDirection == 'up'
			item.animate 'open'
			
	item.on 'change:y', do (item) -> () ->
		[card] = item.childrenWithName('CardBackground')
		[comment] = item.childrenWithName('Comment')
		[cardContent] = item.childrenWithName('CardContent')
		
		between = createModulate(item.y)(0, listY)
		
		card.width = between(itemWidth, Screen.width * 1.2)
		card.height = between(cardHeight, cardHeight * 1.2)
		card.centerX()

		comment.y = between(commentBaseY, commentBaseY + 120)
		comment.scale = between(1, 1.2)
		
		cardContent.y = between(0, 50)
		cardContent.scale = between(1, 1.2)
			
		for thisPage in page.content.children
			if thisPage isnt page.currentPage
				thisPage.children[0].opacity = between(inactiveItemOpacity, 0)
				
		sketch['SearchField'].opacity = between(1, 0)
		sketch['SearchField'].scale = between(1, 0.3)
		
		sketch['OptionsIcon'].opacity = between(1, 0)
		sketch['OptionsIcon'].scale = between(1, 0.3)

sketch['ItemList'].destroy()
sketch['StatusBar'].index = INDEX.STATUS_BAR
	
startAtLayer = page.content.children[4]
startAtLayer.children[0].opacity = 1
startAtLayer.index = INDEX.ACTIVE_CARD
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
		thisLayer.rotationY =
			modulate(pageDragDistance, [0, 200], [0, 10], true) * facing
	
page.onMove ->
	for { children: [thisLayer] } in page.content.children
		distance = abs(thisLayer.screenFrame.x - sideGap)
		thisLayer.opacity =
			modulate(distance, [0, itemWidth], [1, inactiveItemOpacity], true)
		
page.on 'change:currentPage', ->
	for thisPage in page.content.children
		isActive = thisPage == page.currentPage
		thisPage.children[0].draggable.enabled = isActive
		thisPage.index = if isActive then INDEX.ACTIVE_CARD else INDEX.INACTIVE_CARD
	
page.on Events.ScrollStart, ->
	for { children: [thisLayer] } in page.content.children
		thisLayer.draggable.speedY = 0
	
page.on Events.ScrollEnd, ->
	pageDragDistance = 0
	for { children: [thisLayer] } in page.content.children
		thisLayer.draggable.speedY = 1
		thisLayer.animate
			properties:
				rotationY: 0
	
	