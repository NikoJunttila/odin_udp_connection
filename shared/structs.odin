package gamestate

import "core:net"
import rl "vendor:raylib"

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
  name : string,
  using playerinfo : PlayerInfo,
}

PlayerInfo :: struct {
  id : ID,
  hp : int,
  ammo : int,
  pos : rl.Vector2,
}

UpdatePlayerInfo :: struct {
  id : ID,
  moveDIR: i8,
  viewDir: rl.Vector2,
  velocity: rl.Vector2,
  isJumping: bool,
}
