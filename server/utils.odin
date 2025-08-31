package server

// Helper function to convert null-terminated u8 array to string
u8_array_to_string :: proc(arr: []u8) -> string {
	for i in 0..<len(arr) {
		if arr[i] == 0 do return string(arr[:i])
	}
	return string(arr) // No null terminator found, return whole array
}
