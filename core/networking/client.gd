extends "webrtc_client.gd"

var rtc_mp: WebRTCMultiplayer = WebRTCMultiplayer.new()
var sealed = false

func _init():
	var _err = connect("connected", self, "connected")
	_err = connect("disconnected", self, "disconnected")
	_err = connect("offer_received", self, "offer_received")
	_err = connect("answer_received", self, "answer_received")
	_err = connect("candidate_received", self, "candidate_received")
	_err = connect("lobby_joined", self, "lobby_joined")
	_err = connect("lobby_sealed", self, "lobby_sealed")
	_err = connect("peer_connected", self, "peer_connected")
	_err = connect("peer_disconnected", self, "peer_disconnected")

func start(player_name, lobby_name, host_address):
	print(("client.start(%s, %s, %s)" % [player_name, lobby_name, host_address]))
	stop()
	sealed = false
	self.lobby = lobby_name
	connect_to_url(host_address)

func stop():
	print("client.stop()")
	rtc_mp.close()
	close()
	
func sync_motion(network_id, motion):
	var _err = _send_msg("m", network_id, motion)

func _create_peer(id):
	print(("client._create_peer(%s)" % id))
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()

	var _err = peer.initialize({
		"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]
	})

	_err = peer.connect("session_description_created", self, "_offer_created", [id])
	_err = peer.connect("ice_candidate_created", self, "_new_ice_candidate", [id])

	_err = rtc_mp.add_peer(peer, id)

	if id > rtc_mp.get_unique_id():
		_err = peer.create_offer()

	return peer

func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	var _err = send_candidate(id, mid_name, index_name, sdp_name)

func _offer_created(type, data, id):
	if not rtc_mp.has_peer(id):
		return

	rtc_mp.get_peer(id).connection.set_local_description(type, data)

	if type == "offer": 
		var _err = send_offer(id, data)
	else: 
		var _err = send_answer(id, data)

func connected(id):
	var _err = rtc_mp.initialize(id, true)

func lobby_joined(lobby):
	print(("client.lobby_joined(%s)" % lobby))
	self.lobby = lobby

func lobby_sealed():
	sealed = true

func disconnected():
	if not sealed:
		stop()

func peer_connected(id):
	_create_peer(id)

func peer_disconnected(id):
	if rtc_mp.has_peer(id): rtc_mp.remove_peer(id)

func offer_received(id, offer):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_description("offer", offer)

func answer_received(id, answer):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.set_remote_option("answer", answer)

func candidate_received(id, mid, index, sdp):
	if rtc_mp.has_peer(id):
		rtc_mp.get_peer(id).connection.add_ice_candidate(mid, index, sdp)
