later create this style for multiple UDP message structs

MessageType :: enum u8 {
    PLAYER_UPDATE = 1,
    GAMESTATE    = 2,
    CHAT_MESSAGE = 3,
    DISCONNECT   = 4,
}

MessageData :: union {
    shared.Player,
    shared.Gamestate,
    ChatMessage,
    DisconnectMessage,
}

NetworkMessage :: struct {
    type: MessageType,
    data: MessageData,
}
