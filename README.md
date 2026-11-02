

## Wollok Game MCP

Servidor MCP para encolar instrucciones de movimiento para un personaje Wollok.
Expone las herramientas `move_left`, `move_right`, `move_up` y `move_down`.
Cada invocación agrega `left`, `right`, `up` o `down`, respectivamente, a la
lista `pendingMoves`. La herramienta `get_position` informa las coordenadas
actuales del personaje. La posición comienza en `(0, 0)` y se mantiene en
memoria; todavía no está conectada al estado del mundo Wollok.

## Instalación y configuración

Instalá las dependencias con `npm install` y ejecutá `npm run mcp`. El servidor
MCP Streamable HTTP queda disponible en `http://127.0.0.1:3000/mcp`. Configurá
tu cliente MCP para conectarse a esa URL.

El host y el puerto se pueden cambiar con `MCP_HOST` y `MCP_PORT`. El servidor
no se conecta con la native de ejemplo ni con el mundo Wollok. La cola es en
memoria y se reinicia al cerrar el proceso.
