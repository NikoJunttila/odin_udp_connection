package gamestate

import "core:net"

MAX_PLAYERS :: 2
ID :: u32

PacketType :: enum {
 EXPLOSION,
  MAP_CHANGE,
  HANDSHAKE,
}

PacketHandShake :: struct {
  type: PacketType,
  playerID: ID
}
PacketPlayerID :: struct {
  type: PacketType,
  playerID : ID,
}

Gamestate :: struct {
  players : [MAX_PLAYERS]Player,
  time : int,
}

Player :: struct {
  udpEndpoint : net.Endpoint,
  tcpSocket : net.TCP_Socket,
  using playerinfo : PlayerInfo,
}

PlayerInfo :: struct {
  id : ID,
  hp : int,
  ammo : int,
  name : string,
  dead : bool,
}


