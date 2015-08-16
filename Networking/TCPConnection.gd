##
# Author: HODES 
#        (Henrique Otavio do Espirito Santo Becker)
#
# A Class to help on TCP connection within Godot Game Engine
# Credits on exelent reserarch resources, on how to handle 
# Networking related in GDScript: 
#
# Kermer                         - https://github.com/Kermer/Godot/wiki
#
# Theo apud. Kermer              - http://www.godotengine.org/forum/viewtopic.php?f=14&t=565
#
# jrimclean                      - https://github.com/jrimclean
#                                  https://github.com/jrimclean/godot-state-sync-demo
#                                  https://github.com/jrimclean/godot-snapshot-interpolation-demo
#
# GafferOnGames apud. jrimclean  - http://gafferongames.com/
#

extends Node

class Client:
	var tcpConnection = null
	var tcpStream = null
	var ip = ""
	var data = null
	# Just to check if is host uppon data receiving
	var isHost = false

class Server:
	var tcpServer = null
	var clients = []

var serverObject = null
var clientObject = null
var isHost = false
var isConnecting = false
var isReady = false

export(String) var ip = "127.0.0.1"
export(int) var port = 49652

func setIP(ip):
	self.ip = ip
func setPort(port):
	self.port = int(port)
	
func _ready():
	#As HOST Signals
	self.add_user_signal("onClientConnect",[
		{"name":"oClient", "type":TYPE_OBJECT}
		])
	self.add_user_signal("onClientDisconnect",[
		{"name":"oClient", "type":TYPE_OBJECT}
		])
	#As Client Signals
	self.add_user_signal("onConnect", [
		{"name":"ip", "type":TYPE_STRING},
		{"name":"port", "type":TYPE_INT}
		])
	self.add_user_signal("onDisconnect", [
		{"name":"ip", "type":TYPE_STRING},
		{"name":"port", "type":TYPE_INT}
		])
	#As HOST and Client 
	self.add_user_signal("onReceive", [
		{"name":"data", "type":TYPE_OBJECT},
		{"name":"sender", "type":TYPE_OBJECT}
		])

func _process( delta ):
	#As HOST handling
	if self.isHost and self.isReady:
		#Handle client connections
		if serverObject.tcpServer.is_connection_available(): # check if someone's trying to connect
			var oClient = Client.new()
			oClient.tcpConnection = serverObject.tcpServer.take_connection() # accept connection
			oClient.tcpStream = PacketPeerStream.new() # make new data transfer object for him
			oClient.tcpStream.set_stream_peer( oClient.tcpConnection )
			oClient.ip = oClient.tcpConnection.get_connected_host() 
			print("Client connected ",oClient.ip)
			serverObject.clients.append( oClient ) # we need to store him somewhere, that's why we created our Array
			#Emit the signal
			self.emit_signal("onClientConnect", oClient)
		#For each client perform some action
		for client in serverObject.clients:
			if !client.tcpConnection.is_connected(): # NOT connected
				print("Client disconnected")
				var index = serverObject.clients.find( client )
				#Emit the signal
				self.emit_signal("onClientDisconnect", client)
				serverObject.clients.remove( index )
			else:
				var available = client.tcpStream.get_available_packet_count()
				if available > 0:
					for i in range(available):
						dataReceived(client.tcpStream.get_var(), client)
	#As Client Handling
	elif(not self.isHost):
		if not self.isReady: # it's inside _process, so if last status was STATUS_CONNECTING
			if clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				_onClientReady(ip, self.port)
				return # skipping this _process run
		if (clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_NONE 
			or clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_ERROR):
			print( "Server disconnected? " )
			_onDisconnectAsClient(ip,self.port)
			return # skip the process because its disconnected
		#Process the server received data
		if self.isReady:
			var available = clientObject.tcpStream.get_available_packet_count()
			if available > 0:
				for i in range(available):
					#Send without a sender, indicating it has came from server
					dataReceived(clientObject.tcpStream.get_var())

func clearStates():
	self.isHost = false
	self.isReady = false
	self.isConnecting = false

func disconnect():
	if(self.isHost and serverObject != null):
		serverObject.clients.clear()
		serverObject.tcpServer.stop()
		print("Server Disconnected")
	elif(not self.isHost and clientObject != null):
		if(clientObject.tcpConnection.is_connected()):
			clientObject.tcpConnection.disconnect()
		print("Client connection closed")
	clearStates()
	set_process( false )

func start_server():
	if(self.isReady):
		print("Must to disconnect first, in order to start a new server connection.")
		return false
	print("Starting Server")
	#Start new instance for server connection
	#TCP will be used to mantain the connection active
	#also for some reliable operations
	serverObject = Server.new()
	serverObject.tcpServer = TCP_Server.new()
	#Try to listen for connections
	if serverObject.tcpServer.listen( self.port ) == 0:
		print("Server started listening on port ", self.port )
	else:
		print("Failed to start server on port ", self.port)
		return false
	
	self.isHost = true
	self.isReady = true
	set_process( true )
	#Server started success
	return true

func start_client():
	if(self.isReady or self.isConnecting):
		print("Must to disconnect first, in order to start a new client connection.")
		return false
	print("Starting as client connection")
	#Create client object
	clientObject = Client.new()
	clientObject.tcpConnection = StreamPeerTCP.new()
	# Starts the connection
	clientObject.tcpConnection.connect( ip, self.port )
	# Create the packet stream
	clientObject.tcpStream = PacketPeerStream.new()
	clientObject.tcpStream.set_stream_peer( clientObject.tcpConnection )
	# since connection is created from StreamPeerTCP it also inherits its constants
	# get_status() returns following (int 0-3) values:
	if clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_onClientReady(ip, self.port)
		return true
	elif clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		print( "Trying to connect ",ip," :",self.port)
	elif (clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_NONE 
		or clientObject.tcpConnection.get_status() == StreamPeerTCP.STATUS_ERROR):
		print( "Couldn't connect to "+ip+" :",self.port)
		_onDisconnectAsClient(ip, self.port)
		return false
	#Just to make sure it will not be set as host
	self.isHost = false
	set_process(true) # start processing so it can check if connected success
	isConnecting = true
	return true

func _onClientReady(ip, port):
	print( "Connected to ",ip," :", port)
	isReady = true
	isConnecting = false
	self.emit_signal("onConnect", ip, port)
	set_process(true) # start processing if connected

func _onDisconnectAsClient(ip, port):
	self.emit_signal("onDisconnect", ip, port)
	self.disconnect()

#Send data no matter if is Host or client, will decide automatically
func sendData(data, to=null):
	if(not self.isReady):
		print("A connection must be ready in order to start sending data")
		return false;
	if (self.isHost):
		_sendDataAsHost(data, to)
	else:
		_sendDataAsClient(data)
	return true

func _sendDataAsHost(data, to=null):
	if(to!=null):
		to.tcpStream.put_var(data)
	else:
		for oClient in serverObject.clients:
			oClient.tcpStream.put_var(data)

func _sendDataAsClient(data):
	clientObject.tcpStream.put_var(data)

func dataReceived(data, from={"isHost": true}):
	self.emit_signal("onReceive", data, from)
