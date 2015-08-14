extends Node

var oGUI = null
var oWorld = null
var oPlayer = null
var oWeapon = null

var ItemScene = preload("res://Objects/Item.scn")
var EnemiesScenes = [preload("res://enemies/Broom.scn")]

var isMouseDown = false

#Player Data
var PlayerLevel = 1.0
var PlayerHP = 0.0
var PlayerXP = 0.0
var PlayerHPMax = 100.0
var PlayerXPMax = 50.0

#Weapon
var projectileSpeed = 200
#The current Items CODES see Item Object Script
var currentGrip = null
var currentTrigger = null
var currentCannon = null
var currentLoader = null
var currentBurner = null
var currentProjectile = null
var currentFuel = null
#Items Loaded to The Weapon List of all IDs
var itemsLoaded = []

#The item spaw count Down
var itemSpawCountDown = 5
var itemSpawTime = 5
var itemSpawTimeFixed = 5
var itemSpawArea = [300,2400]

#The enemy horde management
var hordeNumber = 0
var hordeStartCountDown = 100
var hordeStartTime = 40
var hordeInProgress = false
var enemySpawCountDown = 8
var enemySpawTime = 8
var enemyQuantityIncrease = 1
var enemyQuantityMax = 0
var enemiesSpawned = 0
var enemiesAlive = 0
var enemySpaws = Vector2Array()

func _ready():
	PlayerHP = PlayerHPMax
	PlayerXP = 0
	set_fixed_process(true)
	set_process_input(true)


func _input(event):
	if event.is_action("fire") and event.is_pressed() and not isMouseDown:
		#spawItem(event.pos + (get_viewport().get_canvas_transform().get_origin() * -1))
		isMouseDown = true
	elif event.is_action("fire") and not event.is_pressed():
		isMouseDown = false

func updateGUI():
	if oGUI != null:
		oGUI.updateGUI()

func damagePlayer(amount):
	PlayerHP -= amount
	if PlayerHP <= 0:
		PlayerHP = 0
		OnDead()
	updateGUI()

func healPlayer(amount):
	PlayerHP += amount
	updateGUI()
	
func givePlayerXP(amount):
	PlayerXP += amount 
	if PlayerXP >= PlayerLevel * PlayerXPMax:
		PlayerLevel += 1
		PlayerHP = PlayerLevel * PlayerHPMax
		PlayerXP = 0
		updateGUI()

func spawItem(pos):
	if oWorld != null:
		var itemInstance = ItemScene.instance()
		itemInstance.mode = 0
		itemInstance.set_pos(pos)
		itemInstance.itemID = randi() % 17
		oWorld.add_child(itemInstance)

func spawProjectile(pos, vecVel):
	if oWorld != null and itemsLoaded.size() > 0:
		var itemInstance = ItemScene.instance()
		itemInstance.mode = 1
		itemInstance.set_pos(pos)
		itemInstance.itemID = get_last_loaded()
		itemsLoaded.resize(itemsLoaded.size()-1)
		oWorld.add_child(itemInstance)
		itemInstance.set_linear_velocity(vecVel*10)
		updateGUI()

func collectItem(itemId):
	itemsLoaded.push_back(itemId)
	updateGUI()
	
func get_last_loaded():
	if itemsLoaded != null and itemsLoaded.size() > 0:
		return itemsLoaded[itemsLoaded.size()-1]
	else:
		return -1

func OnDead():
	var sceneTree = get_tree()
	#Kill All enemies
	var enemies = sceneTree.get_nodes_in_group("enemy")
	var oEnemy = null
	for oEnemy in enemies:
		oEnemy.queue_free()
	oGUI.showLoose()

####################################################
#Enemies Spawing and Horde Management
func addEnemySpaw(spawPos):
	enemySpaws.push_back(spawPos)
	
func checkHordeStatus():
	#Pass if not started properlly
	if oGUI == null and oWorld == null:
		pass
	if hordeStartCountDown > 0 and not hordeInProgress:
		hordeStartCountDown -= 0.1
		oGUI.updateHordeCountDown(hordeStartCountDown)
	if hordeStartCountDown <= 0 and not hordeInProgress:
		#Start a new Horde
		hordeNumber += 1
		hordeStartCountDown = hordeStartTime
		hordeInProgress = true
		enemiesSpawned = 0
		enemySpawCountDown = enemySpawTime
		enemyQuantityMax += enemyQuantityIncrease
		enemiesAlive = enemyQuantityMax
		#Imediatelly Spaw and enemy
		spawEnemy()
		oGUI.updateHordeCountDown("Now !")
		updateGUI()
	
	#Horde Finish 
	if hordeInProgress and enemiesAlive == 0:
		hordeInProgress = false
	
	#Horde in Progress enemies spaws
	if hordeInProgress and enemySpawCountDown > 0:
		enemySpawCountDown -= 0.1
	if hordeInProgress and enemiesSpawned < enemyQuantityMax and enemySpawCountDown <= 0:
		enemySpawCountDown = enemySpawTime
		spawEnemy()

func spawEnemy():
	if oWorld != null and enemySpaws.size() > 0:
		var spawRand = randi() % enemySpaws.size()
		var enemyTypeRand = randi() % EnemiesScenes.size()
		var spawPos = enemySpaws.get(spawRand)
		var enemyInstance = EnemiesScenes[enemyTypeRand].instance()
		enemyInstance.level = 1+int(hordeNumber/2.0)
		enemyInstance.set_pos(spawPos)
		oWorld.add_child(enemyInstance)
		enemiesSpawned += 1
####################################################



func _fixed_process(delta):
	if hordeInProgress:
		itemSpawTime = itemSpawTimeFixed * 5
	else:
		itemSpawTime = itemSpawTimeFixed
	if itemSpawCountDown > 0:
		itemSpawCountDown -= 0.1
	if itemSpawCountDown <= 0:
		var randomPosX = randi() % int(itemSpawArea[1]-itemSpawArea[0]) + int(itemSpawArea[0])
		spawItem(Vector2(randomPosX,0.0))
		itemSpawCountDown = itemSpawTime
	#Update the Horde Status
	checkHordeStatus()