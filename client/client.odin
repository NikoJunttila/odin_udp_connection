package client
import "core:net"
import "core:thread"
import "core:fmt"
import "core:time"

main :: proc() {
	serverEndpoint, ok := net.parse_endpoint("127.0.0.1:8080")
	if !ok {
		fmt.panicf("Failed to create endpoint %v\n", serverEndpoint)
	}
	tcpSock, tsErr := net.dial_tcp_from_endpoint(serverEndpoint)
	if tsErr != nil {
		fmt.eprintf("dial_tcp_from_endpoint error: %v\n", tsErr)
		return
	}
	defer net.close(tcpSock)
	udpSock, err := net.make_unbound_udp_socket(net.family_from_address(serverEndpoint.address))
	if err != nil {
		fmt.println("Failed to make unbound UDP socket", err)
		return
	}
	defer net.close(udpSock)
	thread.create_and_start_with_poly_data(tcpSock, tcp_receive_thread)
	tcp_request_player_id(tcpSock)
	time.sleep(1 * time.Second)
	thread.create_and_start_with_poly_data(udpSock, udp_recv_gamestate)
	thread.create_and_start_with_poly_data2(udpSock, serverEndpoint, udp_send_player)
	thread.create_and_start_with_poly_data3(udpSock, serverEndpoint,"xdd", udp_send_message)
  thread.create_and_start(gameplay_loop)
  for {
    time.sleep(time.Second)
  }
}
