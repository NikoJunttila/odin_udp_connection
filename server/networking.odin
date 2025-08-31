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
			continue
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

udp_recv :: proc(sock: net.UDP_Socket) {
	for {
		networkMessage := shared.NetworkMessage{}
		recv_buffer: [size_of(networkMessage)]u8
		bytes_recv, peerEndpoint, err_recv := net.recv_udp(sock, recv_buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data", err_recv)
			continue
		}
		mem.copy(&networkMessage, mem.raw_data(recv_buffer[:]), size_of(networkMessage))
		#partial switch networkMessage.type {
		case .UPDATE_PLAYER_INFO:
			fmt.println("update_player_stats")
      fmt.println(networkMessage.data)
		case .CHAT_MESSAGE:
			fmt.println("update chat")
      chat_msg := networkMessage.data.(shared.ChatMessage)
			message_str := u8_array_to_string(chat_msg.message[:])
			fmt.println("Chat message:", message_str)
		case:
			fmt.println("other message: ", networkMessage.type)
		}
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
