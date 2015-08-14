
extends CanvasLayer

var Game = null

func _ready():
	# Initialization here
	Game = get_node("/root/Game")
	Game.oGUI = self
	get_node("/root").connect("size_changed", self, "onResizeViewport")

func onResizeViewport():
	get_node("Center").set_pos(get_node("/root").get_rect().size / 2)

func updateGUI():
	var hpPercent = float(Game.PlayerHP/ (Game.PlayerLevel * Game.PlayerHPMax))
	get_node("PlayerInfo/HP").set_scale(Vector2(hpPercent,1))
	
	var xpPercent = float(Game.PlayerXP/ (Game.PlayerLevel * Game.PlayerXPMax))
	get_node("PlayerInfo/XP").set_scale(Vector2(xpPercent,1))
	
	get_node("PlayerInfo/Level").set_text(str(Game.PlayerLevel))
	
	var lastItemLoaded = Game.get_last_loaded()
	if lastItemLoaded > -1:
		get_node("CurrentItem/LastLoaded").show()
		get_node("CurrentItem/LastLoaded").set_frame(lastItemLoaded)
	else:
		get_node("CurrentItem/LastLoaded").hide()
	
	get_node("CurrentItem/QtItems").set_text(str("Items: ",Game.itemsLoaded.size()))
	
	#The Horde Info
	get_node("HordeInfo/Number").set_text(str(Game.hordeNumber))
	get_node("HordeInfo/Status").set_text(str(Game.enemiesAlive,"/",Game.enemyQuantityMax))
	

func showWin():
	get_node("Center/Win").show()
	get_node("WinLooseAnimator").play("ShowWin")
func flashWin():
	get_node("WinLooseAnimator").play("FlashWin")
	
func showLoose():
	get_node("Center/Loose").show()
	get_node("WinLooseAnimator").play("ShowLoose")
func flashLoose():
	get_node("WinLooseAnimator").play("FlashLoose")

func updateHordeCountDown(value):
	get_node("HordeInfo/CountDown").set_text(str(value))