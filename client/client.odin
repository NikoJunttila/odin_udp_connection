package client

import "../shared/"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:os"
gamestate: shared.Gamestate

recv_gamestate :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) -> bool {
	fmt.println("trying to recv_udp")
	gamestate_buf: [size_of(gamestate)]u8
	bytes_recv, _, err_recv := net.recv_udp(sock, gamestate_buf[:])
	fmt.println("received bytes ", bytes_recv)
	if err_recv != nil {
		fmt.println("Failed to receive data", err_recv)
		return false
	}
	mem.copy(&gamestate, mem.raw_data(gamestate_buf[:]), size_of(gamestate))
	fmt.println(gamestate)
	return true
}
upd_send_player :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) {
	player: shared.Player = {
		name = "xdd",
		hp   = 100,
	}
	send_buffer: [size_of(player)]u8
	mem.copy(mem.raw_data(send_buffer[:]), &player, size_of(player))
	bytes_sent, err_send := net.send_udp(sock, send_buffer[:], endpoint)
	if err_send != nil {
		fmt.println("Failed to send data", err_send)
	}
	fmt.printfln("Server sent [ %d bytes ]", bytes_sent)
}

udp_client :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	server_endpoint := net.Endpoint {
		address = local_addr,
		port    = port,
	}
	// for the client, we create an *unbound* UDP socket,
	// the socket will be bound to a free port when we attempt to send data
	sock, err := net.make_unbound_udp_socket(net.family_from_address(local_addr))
	if err != nil {
		fmt.println("Failed to make unbound UDP socket", err)
		return
	}
	fmt.println("Client is ready")
	upd_send_player(sock, server_endpoint)
	for {
		recv_gamestate(sock, server_endpoint)
	}
	defer net.close(sock)
	fmt.println("Closed socket")
}

main :: proc() {
	udp_client("127.0.0.1", 8080)
}
