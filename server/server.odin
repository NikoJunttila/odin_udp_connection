package server

import "../shared/"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:thread"
import "core:time"

gamestate: shared.Gamestate
idCount: shared.ID
players: map[shared.ID]shared.Player

@(init)
setup :: proc "contextless" () {
	idCount = 1
}

send_gamestate :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) {
	empty_endpoint: net.Endpoint
	for {
		for key, player in players {
			if player.udpEndpoint != empty_endpoint {
				send_buffer: [size_of(gamestate)]u8
				mem.copy(mem.raw_data(send_buffer[:]), &gamestate, size_of(gamestate))
				bytes_sent, err_send := net.send_udp(sock, send_buffer[:], player.udpEndpoint)
				if err_send != nil {
					fmt.println("Failed to send data", err_send)
				}
				// fmt.printfln("Server sent updated gamestate [ %d bytes ]", bytes_sent)
			}
		}
		time.sleep(time.Second)
	}
}
udp_recv_player :: proc(sock: net.UDP_Socket) {
	for {
    change := shared.UpdatePlayerInfo{}
		recv_buffer: [size_of(change)]u8
		bytes_recv, player_endpoint, err_recv := net.recv_udp(sock, recv_buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data", err_recv)
			return
		}

		mem.copy(&change, mem.raw_data(recv_buffer[:]), size_of(change))

		if change.id in players {
			player := &players[change.id]
			player.udpEndpoint = player_endpoint
      fmt.println(change)
		}
		time.sleep(time.Second)
	}
}

update_world_state :: proc() {
	for {
		gamestate.time += 1
		time.sleep(time.Second)
	}
}

tcp_connect_player :: proc(clientSock: net.TCP_Socket, clientEndp: net.Endpoint) {
	buf: [size_of(shared.PacketHandShake)]u8
	playerID: shared.ID
	defer net.close(clientSock)
	for {
		n, err := net.recv_tcp(clientSock, buf[:len(buf)])
		if err != nil {
			fmt.println("tcp receive err ", err)
			return
		}
		if n <= 0 {
			//mutex delete player
			//id is always 0 here?
			delete_key(&players, playerID)
			break
		}

		type := shared.PacketType{}
		mem.copy(&type, mem.raw_data(buf[:]), size_of(shared.PacketType))
		#partial switch type {
		case .HANDSHAKE:
			//mutex players
			players[idCount] = shared.Player {
				tcpSocket = clientSock,
				id        = idCount,
				hp        = 100,
			}
			playerID = idCount
			idCount += 1
			packet := shared.PacketHandShake {
				type     = .HANDSHAKE,
				playerID = playerID,
			}
			fmt.println("new player ", playerID)
			mem.copy(mem.raw_data(buf[:]), &packet, size_of(packet))
			net.send_tcp(clientSock, buf[:size_of(packet)])
		}
	}
}

tcp_thread :: proc(tcp_listener: net.TCP_Socket) {
	for {
		clientSock, clientEndp, acceptErr := net.accept_tcp(tcp_listener)
		if acceptErr != net.Accept_Error.None {
			fmt.printfln("TCP accept err, ", acceptErr)
			continue
		}
		net.set_option(clientSock, net.Socket_Option.TCP_Nodelay, true)
		net.set_blocking(clientSock, true)
		thread.create_and_start_with_poly_data2(clientSock, clientEndp, tcp_connect_player)
	}
}

main :: proc() {
	players = make(map[shared.ID]shared.Player)
	addrString := "127.0.0.1:8080"
	endpoint, ok := net.parse_endpoint(addrString)
	if !ok {
		fmt.panicf("Failed to create endpoint %v\n", endpoint)
	}
	tcpSock, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.panicf("Failed to create TCP sock %v}\n", err)
	}
	defer net.close(tcpSock)
	udpSock, uerr := net.make_bound_udp_socket(endpoint.address, endpoint.port)
	if uerr != nil {
		fmt.panicf("Failed to make bound UDP socket %v\n", err)
	}
	defer net.close(udpSock)
	//tcp threads
	thread.create_and_start_with_poly_data(tcpSock, tcp_thread)
	thread.create_and_start(update_world_state)
	//udp threads
	thread.create_and_start_with_poly_data(udpSock, udp_recv_player)
	thread.create_and_start_with_poly_data2(udpSock, endpoint, send_gamestate)
	fmt.println("started server at address: ", addrString)
	for {
		time.sleep(time.Second)
	}
}
