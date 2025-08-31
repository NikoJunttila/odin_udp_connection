package client

import "../shared/"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:os"
import "core:thread"
import "core:time"
import rl "vendor:raylib"

gamestate: shared.Gamestate
playerID: shared.ID

player: shared.Player
udp_recv_gamestate :: proc(sock: net.UDP_Socket) {
	for {
		gamestate_buf: [size_of(gamestate)]u8
		bytes_recv, _, err_recv := net.recv_udp(sock, gamestate_buf[:])
		// fmt.println("received bytes ", bytes_recv)
		if err_recv != nil {
			fmt.println("Failed to receive data", err_recv)
		}
		mem.copy(&gamestate, mem.raw_data(gamestate_buf[:]), size_of(gamestate))
		fmt.println(gamestate)
	}
}

udp_send_player :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint) {
	for {
		data := shared.NetworkMessage {
			type = .UPDATE_PLAYER_INFO,
			data = shared.UpdatePlayerInfo{id = playerID, velocity = velocity},
		}
		send_buffer: [size_of(data)]u8
		mem.copy(mem.raw_data(send_buffer[:]), &data, size_of(data))
		bytes_sent, err_send := net.send_udp(sock, send_buffer[:], endpoint)
		if err_send != nil {
			fmt.println("Failed to send data", err_send)
		}
		fmt.println("sent player updates")
		time.sleep(time.Second)
	}
}
udp_send_message :: proc(sock: net.UDP_Socket, endpoint: net.Endpoint, message: string) {
	for {
		u8mes: [128]u8
		copy(u8mes[:], message)
		data := shared.NetworkMessage {
			type = .CHAT_MESSAGE,
			data = shared.ChatMessage{id = playerID, message = u8mes},
		}
		send_buffer: [size_of(data)]u8
		mem.copy(mem.raw_data(send_buffer[:]), &data, size_of(data))
		bytes_sent, err_send := net.send_udp(sock, send_buffer[:], endpoint)
		if err_send != nil {
			fmt.println("Failed to send data", err_send)
		}
		fmt.println("sent chat message: ", message)
		// fmt.printfln("client sent [ %d bytes ]", bytes_sent)
		time.sleep(time.Second)
	}
}

tcp_request_player_id :: proc(tcpSock: net.TCP_Socket) {
	buf: [2048]u8
	playerIDPacket := shared.PacketPlayerID {
		type = .HANDSHAKE,
	}
	mem.copy(mem.raw_data(buf[:]), &playerIDPacket, size_of(shared.PacketPlayerID))
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
			player.id = playerID
			fmt.println("received ID ", playerID)
		case:
			fmt.println("default case: ", packetType)
		}

		// case .EXPLOSION:
		// 	expPacket := shared.PacketExplosion{}
		// 	mem.copy(&expPacket, mem.raw_data(buf[:]), size_of(expPacket))
		//
		// 	expl_anim_add(expPacket.pos)
		// }
	}
}
