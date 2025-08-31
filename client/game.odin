package client

import rl "vendor:raylib"
velocity: rl.Vector2
WINDOW_HEIGH :: 700
WINDOW_WIDTH :: 700
pPos : rl.Vector2
pSize :: 100

gameplay_loop :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGH, "Client gameplay")

	for !rl.WindowShouldClose() {
    movement()
    draw_all()
	}
}

movement :: proc(){
  if rl.IsKeyDown(.DOWN){
  velocity = {0,1}
  }
  if rl.IsKeyDown(.UP){
  velocity = {0,-1}
  }
  if rl.IsKeyDown(.LEFT){
  velocity = {-1,0}
  }
  if rl.IsKeyDown(.RIGHT){
  velocity = {1,0}
  }
  pPos += velocity
  pPos.x = clamp(pPos.x, 0, WINDOW_WIDTH-pSize)
  pPos.y = clamp(pPos.y, 0, WINDOW_HEIGH-pSize)
}

draw_all :: proc(){
  rl.BeginDrawing()
  rl.ClearBackground(rl.DARKGREEN)
  rl.DrawRectangleV({pPos.x,pPos.y},200,rl.SKYBLUE)

  camera := rl.Camera2D{zoom=1}
  rl.BeginMode2D(camera)
  rl.EndMode2D()
  
  rl.EndDrawing()
}
