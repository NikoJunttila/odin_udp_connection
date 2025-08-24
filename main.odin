package main

import "core:fmt"
import "core:mem"
import "core:net"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

cat :: struct {
	name:    string,
	age:     int,
	playing: bool,
}
init_cat :: proc(name: string) -> cat {
	return cat{age = 0, name = name, playing = false}
}

global_cat: cat
main :: proc() {
	global_cat = init_cat("hellope")
	for {
		buffer: [size_of(global_cat)]u8
		mem.copy(mem.raw_data(buffer[:]), &global_cat, size_of(global_cat))
		fmt.println(buffer)

		cat_buf: cat
		mem.copy(&cat_buf, mem.raw_data(buffer[:]), size_of(cat_buf))
		fmt.println(cat_buf)
		update_cat()
		time.sleep(time.Second)
	}
}

update_cat :: proc() {
	global_cat.age += 1
}


// fmt.println("xdd")
// rl.InitWindow(700,700,"test")
// // rect := rl.Rectangle{x:400,y:400,width:200,height:200}
// rect := rl.Rectangle{x=400,y=400,width=200,height=200}
// rect2 := rl.Rectangle{x=100,y=100,width=200,height=200}
// for !rl.WindowShouldClose(){
//   rl.BeginDrawing()
//   rl.BeginMode2D(rl.Camera2D{zoom=1})
//   rl.ClearBackground(rl.BLUE)
//   rl.DrawRectangleRounded(rect,0.5,10,rl.RED)
//   rl.DrawRectangleRec(rect2,rl.PURPLE)
//   rl.EndMode2D()
//   rl.EndDrawing()
//   free_all(context.temp_allocator)
// }
