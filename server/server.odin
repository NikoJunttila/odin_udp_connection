package server

import "../shared/"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:time"
import "core:thread"

gamestate: shared.Gamestate
player_count : int
@(init)
setup :: proc "contextless" () {
	gamestate.paused = false
	gamestate.world_health = 100_000
}

send_gamestate :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) {
	empty_endpoint: net.Endpoint
	for player in gamestate.players {
		if player.udp_endpoint != empty_endpoint {
      fmt.println("sending data to ",player.udp_endpoint)
			send_buffer: [size_of(gamestate)]u8
			mem.copy(mem.raw_data(send_buffer[:]), &gamestate, size_of(gamestate))
			bytes_sent, err_send := net.send_udp(sock, send_buffer[:], player.udp_endpoint)
			if err_send != nil {
				fmt.println("Failed to send data", err_send)
			}
			fmt.printfln("Server sent [ %d bytes ]", bytes_sent)
		}
	}
  time.sleep(time.Second)
}
udp_recv_player :: proc(sock: net.UDP_Socket) {
	for {
    fmt.println("waiting for player")
		player: shared.Player
		recv_buffer: [size_of(player)]u8
		bytes_recv, player_endpoint, err_recv := net.recv_udp(sock, recv_buffer[:])
		fmt.println("received player ", player_endpoint)
		if err_recv != nil {
			fmt.println("Failed to receive data", err_recv)
			return
		}
		mem.copy(&player, mem.raw_data(recv_buffer[:]), size_of(player))
		player.udp_endpoint = player_endpoint
		fmt.println(player)
		gamestate.players[player_count] = player
    player_count += 1
    time.sleep(time.Second)
	}
}
udp_server :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = port,
	}
	// for the server, we create a *bound* UDP socket,
	// because we want to start listen the port immediately
	sock, err := net.make_bound_udp_socket(endpoint.address, endpoint.port)
	if err != nil {
		fmt.println("Failed to make bound UDP socket", err)
		return
	}
  thread.create_and_start_with_poly_data(sock, udp_recv_player)
	fmt.printfln("Listening on UDP: %s", net.endpoint_to_string(endpoint))
	recv_buffer: [size_of(gamestate)]u8
	for {
		send_gamestate(sock, endpoint)

		// `net.endpoint_to_string` creates temporarily-allocated string
		free_all(context.temp_allocator)
	}
	net.close(sock)
	fmt.println("Closed socket")
}

update_world_state :: proc(){
  for {
    gamestate.world_health -= 10
    gamestate.time += 1
    time.sleep(time.Second)
  }
}

main :: proc() {
  thread.create_and_start(update_world_state)
	udp_server("127.0.0.1", 8080)
}
