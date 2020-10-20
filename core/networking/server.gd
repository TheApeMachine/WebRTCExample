extends Node

const ALFNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
var _alfnum = ALFNUM.to_ascii()
var rand: RandomNumberGenerator = RandomNumberGenerator.new()
var lobbies: Dictionary = {}
var server: WebSocketServer = WebSocketServer.new()
var peers: Dictionary = {}

onready var parent = get_parent().get_parent()

class Peer extends Reference:

	var id = -1
	var lobby = ""

	func _init(peer_id):
		print(("Peer._init(%s)" % peer_id))
		id = peer_id

class Lobby extends Reference:

	var peers: Array = []
	var host: int =  -1
	var sealed: bool = false

	func _init(host_id: int):
		print(("Lobby._init(%s)" % host_id))
		host = host_id

	func join(peer_id, server) -> bool:
		print(("Lobby.join(%s, %s)" % [peer_id, server]))
		
		if sealed: return false
		if not server.has_peer(peer_id): return false

		var new_peer : WebSocketPeer = server.get_peer(peer_id)
		var _err = new_peer.put_packet(("connected %d\n" % (1 if peer_id == host else peer_id)).to_utf8())

		for p in peers:
			if not server.has_peer(p):
				continue

			server.get_peer(p).put_packet(("peer_connected %d\n" % peer_id).to_utf8())
			_err = new_peer.put_packet(("peer_connected %d\n" % (1 if p == host else p)).to_utf8())

		peers.push_back(peer_id)
		return true

	func leave(peer_id, server) -> bool:
		if not peers.has(peer_id): return false

		peers.erase(peer_id)
		var close = false

		if peer_id == host:
			close = true

		for p in peers:
			if not server.has_peer(p): return close

			if close:
				server.disconnect_peer(p)
			else:
				server.get_peer(p).put_packet(("peer_disconnected %d\n" % peer_id).to_utf8())

		return close

	func seal(peer_id, server) -> bool:
		if host != peer_id: return false
		sealed = true

		for p in peers:
			server.get_peer(p).put_packet("seal_lobby\n").to_utf8()

		return true

func _init():
	var _err = server.connect("data_received", self, "_on_data")
	_err = server.connect("client_connected", self, "_peer_connected")
	_err = server.connect("client_disconnected", self, "_peer_disconnected")

func _process(delta):
	poll()

func listen(port):
	stop()
	rand.seed = OS.get_unix_time()
	var _err = server.listen(port)
	print("server listening...")

func stop():
	server.stop()
	peers.clear()

func poll():
	if not server.is_listening():
		return

	server.poll()

func _peer_connected(id, protocol=""):
	print(("_peer_connected(%s, %s)" % [id, protocol]))
	peers[id] = Peer.new(id)
	parent.network.add_player(id)

func _peer_disconnected(id, was_clean=false):
	print(("_peer_disconnected(%s, %s)" % [id, was_clean]))

	var lobby = peers[id].lobby

	if lobby and lobbies.has(lobby):
		peers[id].lobby = ""

		if lobbies[lobby].leave(id, server):
			var _err = lobbies.erase(lobby)

	var _err = peers.erase(id)

func _join_lobby(peer, lobby) -> bool:
	print(("_join_lobby(%s, %s)" % [peer, lobby]))

	if lobby == "":
		for _i in range(0, 32):
			lobby += char(_alfnum[rand.randi_range(0, ALFNUM.length()-1)])

		lobbies[lobby] = Lobby.new(peer.id)

	elif not lobbies.has(lobby):
		return false

	lobbies[lobby].join(peer.id, server)
	peer.lobby = lobby
	var _err = server.get_peer(peer.id).put_packet(("join_lobby %s\n" % lobby).to_utf8())
	return true

func _on_data(id):
	if not _parse_msg(id):
		server.disconnect_peer(id)

func _parse_msg(id) -> bool:
	var pkt_str: String = server.get_peer(id).get_packet().get_string_from_utf8()
	#print(("server._parse_msg(%s) -> %s" % [id, pkt_str]))

	var payload = pkt_str.split(":", false, 0)
	
	if payload[0] == "m":
		parent.network.players[int(payload[1])].networked_move(payload[2])
	
	return true
