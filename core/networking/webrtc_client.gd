extends Node

export var autojoin = true
export var lobby = ""

var client: WebSocketClient = WebSocketClient.new()
var code = 1000
var reason = "Unknown"

signal lobby_joined(lobby)
signal connected(id)
signal disconnected()
signal peer_connected(id)
signal peer_disconnected(id)
signal offer_received(id, offer)
signal answer_received(id, answer)
signal candidate_received(id, mid, index, sdp)
signal lobby_sealed()

func _init():
	var _err = client.connect("data_received", self, "_parse_msg")
	_err = client.connect("connection_established", self, "_connected")
	_err = client.connect("connection_closed", self, "_closed")
	_err = client.connect("connection_error", self, "_closed")
	_err = client.connect("server_close_request", self, "_closed")

func connect_to_url(url):
	print(("webrtc_client.connect_to_url(%s)" % url))
	close()
	code = 1000
	reason = "Unknown"
	var _err = client.connect_to_url(url)

func close():
	client.disconnect_from_host()

func _closed(_was_clean = false):
	emit_signal("disconnected")

func _close_request(c, r):
	self.code = c
	self.reason = r

func _connected(protocol = ""):
	print(("webrtc_client._connected(%s)" % protocol))
	client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

	if autojoin:
		join_lobby(lobby)

func _parse_msg():
	var pkt_str : String = client.get_peer(1).get_packet().get_string_from_utf8()
	print(pkt_str)
	emit_signal(pkt_str)

func join_lobby(l):
	print(("webrtc_client.join_lobby(%s)" % l))
	return client.get_peer(1).put_packet(("join_lobby %s\n" % lobby).to_utf8())

func seal_lobby(_l):
	return client.get_peer(1).put_packet(("seal_lobby\n").to_utf8())

func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg("candidate_received", id, "\n%s\n%d\n%s" % [mid, index, sdp])

func send_offer(id, offer) -> int:
	return _send_msg("offer_received", id, offer)

func send_answer(id, answer) -> int:
	return _send_msg("answer_received", id, answer)

func _send_msg(type, id, data) -> int:
	return client.get_peer(1).put_packet(("%s:%d:%s" % [type, id, data]).to_utf8())

func _process(_delta):
	var status : int = client.get_connection_status()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		client.poll()
