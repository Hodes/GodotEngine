extends Node

var oConnection = null

var txIP = null
var txPort = null
var btnStartServer = null
var btnStartClient = null
var btnDisconnect = null
var output = null
var input = null

func _ready():
	txIP = get_node("txIP")
	txPort = get_node("txPort")
	btnStartServer = get_node("btnStartServer")
	btnStartClient = get_node("btnStartClient")
	btnDisconnect = get_node("btnDisconnect")
	output = get_node("output")
	input = get_node("input")
	
	oConnection = get_node("/root/TCPConnection")
	# Add the node to the scene tree, so it can _process
	#add_child(oConnection)
	#Register the signals for client handling
	oConnection.connect("onConnect", self, "onConnectAsClient")
	oConnection.connect("onDisconnect", self, "onDisconnect")
	#Register the signals for server handling
	oConnection.connect("onClientConnect", self, "onClientConnect")
	oConnection.connect("onClientDisconnect", self, "onClientDisconnect")
	#On receiving messages
	oConnection.connect("onReceive", self, "onReceive")

func handleDisconnect():
	btnStartServer.set_disabled(false)
	btnStartClient.set_disabled(false)
	btnDisconnect.set_disabled(true)
	output.add_text( "Connection Closed "); output.newline()

func setConnectionInfo():
	oConnection.setIP(txIP.get_text())
	oConnection.setPort(txPort.get_text())

func _on_btnStartServer_pressed():
	setConnectionInfo()
	if oConnection.start_server():
		btnStartServer.set_disabled(true)
		btnStartClient.set_disabled(true)
		btnDisconnect.set_disabled(false)
		output.add_text( "Server started at port "+str(oConnection.port)); output.newline()
	else:
		output.add_text( "Error starting server, maybe the por is already in use."); output.newline()

func _on_btnStartClient_pressed():
	setConnectionInfo()
	output.add_text( "Starting as client on "+oConnection.ip+":"+str(oConnection.port)); output.newline()
	btnStartServer.set_disabled(true)
	btnStartClient.set_disabled(true)
	btnDisconnect.set_disabled(false)
	if not oConnection.start_client():
		output.add_text( "Error starting client on "+oConnection.ip+":"+str(oConnection.port)); output.newline()
		handleDisconnect()

func _on_btnDisconnect_pressed():
	oConnection.disconnect()
	handleDisconnect()

func _on_input_input_event( ev ):
	if ev.is_action("message_send") and not input.get_text().empty():
		if oConnection.sendData(input.get_text()):
			output.add_text( "Sent > "+input.get_text()); output.newline()
		input.set_text("")

func onConnectAsClient(ip, port):
	output.add_text( "Connected on "+ip+":"+str(port)); output.newline()

func onDisconnect(ip, port):
	output.add_text( "Disconnected from "+ip+":"+str(port)); output.newline()
	handleDisconnect()

func onClientConnect(oClient):
	output.add_text( "Client "+oClient.ip+" has connected on server."); output.newline()

func onClientDisconnect(oClient):
	output.add_text( "Client "+oClient.ip+" has disconnected from server."); output.newline()

func onReceive(data, sender):
	if not sender.isHost:
		output.add_text( "From "+sender.ip+" > "+data); output.newline()
	else:
		output.add_text( "Server > "+data); output.newline()




