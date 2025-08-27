package client

import "../shared/"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:os"
import "core:thread"
gamestate: shared.Gamestate
playerID : shared.ID

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

// upd_send_player :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) { player: shared.Player = {
//     id = player_id,
// 		name = "xdd",
// 	}
// 	send_buffer: [size_of(player)]u8
// 	mem.copy(mem.raw_data(send_buffer[:]), &player, size_of(player))
// 	bytes_sent, err_send := net.send_udp(sock, send_buffer[:], endpoint)
// 	if err_send != nil {
// 		fmt.println("Failed to send data", err_send)
// 	}
// 	fmt.printfln("Server sent [ %d bytes ]", bytes_sent)
// }

udp_client :: proc(serverEndpoint : net.Endpoint) {
	// for the client, we create an *unbound* UDP socket,
	// the socket will be bound to a free port when we attempt to send data
	sock, err := net.make_unbound_udp_socket(net.family_from_address(serverEndpoint.address))
	if err != nil {
		fmt.println("Failed to make unbound UDP socket", err)
		return
	}
	fmt.println("Client is ready")
	// upd_send_player(sock, server_endpoint)
	for {
		recv_gamestate(sock, serverEndpoint)
	}
	defer net.close(sock)
	fmt.println("Closed socket")
}

tcp_request_player_id :: proc(tcpSock: net.TCP_Socket){
  buf: [2048]u8
  playerIDPacket := shared.PacketPlayerID{type = .HANDSHAKE}
  mem.copy(mem.raw_data(buf[:]),&playerIDPacket, size_of(shared.PacketPlayerID))
  net.send_tcp(tcpSock, buf[:size_of(shared.PacketPlayerID)])
}

tcp_receive_thread :: proc(sock: net.TCP_Socket) {
	buf: [size_of(shared.PacketHandShake)]u8

	for {
		_, rerr := net.recv_tcp(sock, buf[:])
		if rerr != nil {
			fmt.eprintf("tcp receiving error: %v\n", rerr) 
			return
		}

		packetType: shared.PacketType 
		mem.copy(&packetType, mem.raw_data(buf[:]), size_of(packetType))

		#partial switch packetType {
		case .HANDSHAKE:
			handshakePacket := shared.PacketHandShake{}
			mem.copy(&handshakePacket, mem.raw_data(buf[:]), size_of(handshakePacket))
			playerID = handshakePacket.playerID
      fmt.println("received ID ", playerID)
    }
		// case .EXPLOSION:
		// 	expPacket := shared.PacketExplosion{}
		// 	mem.copy(&expPacket, mem.raw_data(buf[:]), size_of(expPacket))
		//
		// 	expl_anim_add(expPacket.pos)
		// }
	}
}

main :: proc() {
  endpoint, ok := net.parse_endpoint("127.0.0.1:8080")
  if !ok{
    fmt.panicf("Failed to create endpoint %v\n",endpoint)
  }
	tcpSock, tsErr := net.dial_tcp_from_endpoint(endpoint)
	if tsErr != nil {
		fmt.eprintf("dial_tcp_from_endpoint error: %v\n", tsErr)
		return
	}
	defer net.close(tcpSock)
  thread.create_and_start_with_poly_data(tcpSock, tcp_receive_thread)
  tcp_request_player_id(tcpSock)
	udp_client(endpoint)
}
