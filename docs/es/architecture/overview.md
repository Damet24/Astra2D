# Descripción general de la arquitectura

Astra 2D está organizado como un conjunto pequeño de módulos independientes que
se conectan mediante un único objeto `Engine`. El motor proporciona mecanismos
como el ciclo de frames, las escenas, los recursos, la entrada y el audio; cada
escena coordina su propio comportamiento y los componentes que necesita.

Esta página explica cómo se relacionan los módulos entre sí. Documenta lo que el
motor hace realmente hoy, para que la referencia de módulos y las guías se
construyan sobre un modelo mental compartido.

## El motor de un vistazo

En la parte superior, `main.lua` crea un `Engine` y le reenvía los callbacks de
LÖVE. El motor construye los servicios compartidos, carga las escenas a través
del gestor de escenas. Las escenas del juego pueden crear un `World`, cámaras
y componentes de renderizado según sus necesidades.

```text
                          main.lua
     reenvía load / update / draw / quit de LÖVE
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│ Engine                                                             │
│   ciclo de frames · ventana · viewport (Shove)                     │
│                                                                    │
│   posee ──▶ ResourceManager   GameContext   SceneLoader            │
│             SceneManager      AudioManager  InputManager           │
└──────────────────────────────┬────────────────────────────────────┘
                               │ Engine:load() apila la escena inicial
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneManager              pila de { id, scene }                    │
│   push · pop · replace · clear · clearAndPush   (diferido)         │
└──────────────────────────────┬────────────────────────────────────┘
                               │ carga a través de
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneLoader        scenesPath .. "." .. sceneName  →  Scene.new()  │
└──────────────────────────────┬────────────────────────────────────┘
                               │ construye
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ Scene                 ciclo de vida + una parte del juego          │
│   puede usar ──▶ World (ECS + física)   CameraManager              │
│                  RenderPipeline         TilemapRender              │
└───────────────────────────────────────────────────────────────────┘

Servicios compartidos accesibles desde una escena mediante su GameContext:
  GameContext ──▶ resourceManager · audioManager · sceneManager
                  inputManager · viewport
  ResourceManager ── compartido por ──▶ AudioManager y Escenas (consumidores)
```

Dos ideas facilitan seguir el resto de la arquitectura:

- **El motor construye, el juego describe.** `Engine.new(config)` recibe
  descripciones (una escena inicial, definiciones de recursos, mapas de entrada,
  resoluciones) y las convierte en objetos vivos. Las escenas usan esos servicios
  compartidos a través del contexto y pueden crear sus propios mundos y cámaras.
- **Las escenas ven un `GameContext`, no el motor.** Todo lo que una escena
  necesita se le entrega a través del contexto, lo que mantiene a las escenas
  desacopladas de cómo se ensambla el motor.

## El ciclo de vida de un frame

Astra 2D no reemplaza el bucle principal de LÖVE. `main.lua` reenvía los callbacks de ciclo de vida, y cada uno se corresponde con un método del motor:

| Callback de LÖVE | Método del motor | Qué ocurre |
| --- | --- | --- |
| `love.load` | `Engine:load()` | Aplica la configuración de la ventana y el color de fondo, crea el viewport, apila `initialScene`, procesa la transición pendiente e instala los callbacks de entrada. |
| `love.update(dt)` | `Engine:update(dt)` | Despacha eventos, actualiza los flancos de los ejes del mando, actualiza la pila de escenas, luego el audio y por último limpia el estado transitorio de entrada y el delta del ratón. |
| `love.draw` | `Engine:draw()` | Dibuja la pila de escenas dentro del viewport de resolución virtual. |
| `love.quit` | `Engine:quit()` | Destruye la pila de escenas, detiene el audio y libera todos los recursos. |

Durante `Engine:load()`, el motor también instala sus propios manejadores para `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `mousemoved`, `gamepadpressed`, `gamepadreleased`, `gamepadaxis`, `joystickadded` y `joystickremoved`. Los juegos no reenvían esos eventos; cada manejador llama al método correspondiente del motor, que actualiza el `InputManager`.

El orden dentro de `Engine:update` es importante:

1. `EventManager:dispatch()` entrega los eventos encolados, incluidas las conexiones de mando.
2. `InputManager:update()` recalcula el estado de los ejes del mando y sus flancos de pulsación y liberación.
3. `SceneManager:update(dt)` actualiza las escenas activas y, al final, procesa
   las transiciones solicitadas durante el frame.
4. `AudioManager:update(dt)` libera los sonidos que terminaron de reproducirse.
5. `InputManager:reset()` limpia el estado de "recién pulsado" y "recién
   soltado" y el delta del ratón después de que las escenas los hayan leído.

La entrada se limpia al final a propósito: una escena lee `isJustPressed` mientras
se ejecuta, y el flag se descarta después de que las escenas seleccionadas hayan
tenido la oportunidad de reaccionar. Los ejes del mando ya están resueltos antes
de actualizar las escenas, así que una asignación por eje informa de sus flancos
en el mismo frame.

Al cerrar, `Engine:quit()` encola el vaciado de la pila de escenas y procesa las
operaciones pendientes. Las operaciones que ya estaban en la cola se ejecutan
antes del vaciado. Este llama a `onExit` solo en la escena superior y después a
`onDestroy` en todas las escenas, de arriba hacia abajo. A continuación, el
motor apaga el audio y libera los recursos restantes.

Estas fases no están protegidas contra errores: si una falla, no se garantiza
que se ejecuten las fases posteriores.

## Guías de módulos

Estas páginas describen las responsabilidades, la configuración, las interfaces
y las relaciones de cada módulo. La [referencia de API](/es/api/) ofrece una
consulta rápida y separada de los métodos.

| Módulo | Función |
| --- | --- |
| [Engine](modules/engine.md) | Ensambla los servicios y dirige el ciclo de LÖVE. |
| [GameContext](modules/game-context.md) | Da acceso a los servicios compartidos desde las escenas. |
| [SceneManager](modules/scene-manager.md) | Administra la pila de escenas y las transiciones diferidas. |
| [SceneLoader](modules/scene-loader.md) | Construye instancias de escenas a partir de nombres de módulos. |
| [Scene](modules/scene.md) | Define el ciclo de vida y las políticas de actualización y dibujo. |
| [World](modules/world.md) | Contiene el estado ECS, los sistemas, los eventos y la física. |
| [ResourceManager](modules/resource-manager.md) | Carga y comparte recursos entre consumidores. |
| [InputManager](modules/input-manager.md) | Asigna acciones de teclado, ratón y mando a nombres de acción. |
| [AudioManager](modules/audio-manager.md) | Coordina música y efectos de sonido. |
| [CameraManager](modules/camera-manager.md) | Administra las cámaras y vistas de mundo de una escena. |
| [Renderizado](modules/rendering.md) | Conecta viewport, cámara, pipeline y renderizadores. |

## Cómo trabajan juntos los módulos

- **Transiciones diferidas.** Las escenas nunca modifican la pila directamente.
  Llaman a `sceneManager:push/pop/replace/...`, y el `SceneManager` aplica las
  solicitudes al final de la actualización de escenas. Esto mantiene intacta la
  escena en ejecución mientras termina su frame.
- **Los consumidores comparten recursos.** El `ResourceManager` es el único lugar
  donde se cargan recursos. Las escenas y el `AudioManager` son consumidores; un
  recurso permanece cargado mientras algún consumidor lo necesite y se libera
  cuando el último lo suelta.
- **Actualización y dibujo son políticas separadas.** `updateBelow` y
  `drawBelow` deciden, por escena, si las escenas de debajo siguen simulándose o
  siguen dibujándose. Un menú de pausa puede dibujar el nivel que tiene debajo
  mientras detiene su simulación, y una escena puede actualizarse sin dibujarse.
- **Una única cadena de coordenadas.** Ventana física → viewport lógico → mundo
  de la cámara → pipeline. Las conversiones ocurren solo en las fronteras:
  `screenToViewport` (física → lógica) y `worldCoords` (lógica → mundo).

## Dónde encaja el juego

Tu juego proporciona descripciones y contenido; el motor proporciona los
mecanismos.

| Tu juego proporciona | El motor lo convierte en |
| --- | --- |
| `initialScene` | La primera escena apilada en la pila. |
| `scenesPath` | El prefijo de módulo usado para cargar escenas (por defecto `game.scenes`). |
| `resourceDefinitions` / `resourceLoaders` | Las definiciones y los cargadores usados por el `ResourceManager`. |
| `inputMaps` | La tabla de acciones usada por el `InputManager`, incluidas las asignaciones de teclado, ratón y mando. |
| `window` / `rendering` / `audio` | Modo de ventana, resolución lógica, fondo y volúmenes. |
| Módulos de escena | Instancias creadas por el `SceneLoader` y dirigidas por el `SceneManager`. |
| Mundos, sistemas, cámaras, pipelines | Creados por las escenas cuando los necesitan, normalmente en `onLoad`. |

## Notas de diseño

`engine/scenes.md` es un documento de diseño que describe la dirección prevista
del sistema de escenas. Algunas de sus ideas aún no están implementadas, entre
ellas un `SceneRegistry`/`SceneFactory`, reglas de transición definidas por el
juego, validación del contexto de origen para solicitudes pendientes y un
`GameState`. Donde esta página y ese documento no coincidan, esta página describe
la implementación actual.

La [guía de GameContext](modules/game-context.md) explica cómo se ensamblan los
servicios compartidos y se entregan a las escenas.

## Siguientes pasos

- [Introducción](/es/getting-started/introduction) para los conceptos clave.
- [Tu primer proyecto](/es/getting-started/first-project) para construir una
  escena con entrada, movimiento y un recurso.
- Las [guías de módulos](#guias-de-modulos) para conocer la arquitectura y las interfaces de cada módulo.
