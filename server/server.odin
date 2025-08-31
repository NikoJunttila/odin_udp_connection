package server

import "../shared/"
import "core:fmt"
import "core:net"
import "core:thread"
import "core:time"

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
	thread.create_and_start_with_poly_data(udpSock, udp_recv)
	thread.create_and_start_with_poly_data2(udpSock, endpoint, send_gamestate)
	fmt.println("started server at address: ", addrString)
	for {
		time.sleep(time.Second)
	}
  delete(players)
}
