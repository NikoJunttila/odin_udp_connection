package gamestate

import "core:net"

MAX_PLAYERS :: 2

Gamestate :: struct {
  players : [MAX_PLAYERS]Player,
  paused : bool,
  world_health : int,
  time : int,
}

Player :: struct {
  udp_endpoint : net.Endpoint,
  hp : int,
  ammo : int,
  name : string,
  dead : bool,
}


