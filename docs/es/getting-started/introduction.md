# Introducción

Astra 2D es un motor de juego 2D modular creado con Lua y [LÖVE](https://love2d.org/).
Proporciona la estructura para escenas, entidades, recursos, entrada, audio,
cámaras y tilemaps, y deja las reglas de tu juego en tu propio código.

Si eres nuevo en Astra 2D, esta página explica qué ofrece el motor y cómo encajan
sus piezas. La página de [Instalación](/es/getting-started/installation) pone en
marcha el proyecto de ejemplo, y [Tu primer proyecto](/es/getting-started/first-project)
te guía para crear un juego pequeño desde cero. La [CLI del proyecto](/es/getting-started/cli)
opcional puede generar por ti el punto de entrada, los archivos de configuración
y una escena inicial.

## Qué ofrece Astra 2D

- **Escenas con un ciclo de vida gestionado.** Las escenas se apilan, se
  reemplazan y se limpian mediante un `SceneManager`, con los callbacks
  `onLoad`, `onEnter`, `onExit` y `onDestroy`.
- **Un Entity Component System (ECS).** Las entidades son identificadores
  simples, mientras que los componentes y los sistemas contienen los datos y el
  comportamiento de tu juego.
- **Recursos centralizados.** Las imágenes, los sonidos y las fuentes se cargan
  bajo demanda y se liberan cuando sus consumidores ya no los necesitan.
- **Entrada basada en acciones.** Define acciones con nombre, como `jump` o
  `move_left`, una sola vez, y consúltalas desde cualquier escena.
- **Cámaras por escena.** Cada escena puede crear su propio gestor de cámaras y
  su cámara activa, con soporte para múltiples viewports.
- **Gestión de audio.** La música y los efectos de sonido comparten el gestor de
  recursos y admiten volúmenes independientes de master, música y efectos.
- **Renderizado de tilemaps.** Los mapas y tilesets de Tiled se pueden dibujar a
  través del pipeline de render.
- **Física.** El ECS integra el módulo de física de LÖVE mediante un conjunto de
  sistemas de física y colisiones.

## Cómo se organiza el motor

El repositorio separa el motor del juego que lo usa:

```text
engine/   Módulos del motor y bibliotecas de terceros en engine/lib
game/     El juego de ejemplo: escenas, recursos, mapas de entrada y assets
main.lua  Punto de entrada que crea el motor y reenvía los callbacks de LÖVE
```

Tu juego conserva sus propias escenas, definiciones de recursos, mapas de
entrada y assets. El motor solo necesita saber dónde están.

## Conceptos clave

| Concepto | Responsabilidad |
| --- | --- |
| `Engine` | Crea los gestores y, al cargar, configura opcionalmente la ventana, prepara el viewport y carga la escena inicial. |
| `GameContext` | Pasa servicios compartidos, como los gestores de recursos, escenas, entrada y audio, a las escenas. |
| `SceneManager` | Mantiene la pila de escenas y procesa las transiciones. |
| `Scene` | Coordina una parte autocontenida del juego, como un menú o un nivel. |
| `World` | Almacena entidades, componentes y sistemas de una escena. |
| `ResourceManager` | Carga recursos bajo demanda y los libera cuando dejan de usarse. |
| `InputManager` | Asigna teclas a acciones con nombre y expone su estado. |
| `AudioManager` | Reproduce música y efectos de sonido a través del gestor de recursos. |
| `CameraManager` | Crea y selecciona las cámaras que usa una escena. |

Las escenas reciben un `GameContext`, no el motor. Esto mantiene a las escenas
centradas en el comportamiento del juego y permite que el motor controle cómo se
crean los servicios.

## El ciclo de vida de un frame

Astra 2D no reemplaza el bucle principal de LÖVE. Tu `main.lua` crea un `Engine` y le reenvía los callbacks de LÖVE. Para ver un punto de entrada y una escena completos, consulta [Tu primer proyecto](/es/getting-started/first-project).

Al iniciar, `Engine:load()` configura opcionalmente la ventana, prepara el
viewport de resolución lógica y apila la escena inicial.

En cada frame, `Engine:update(dt)` actualiza las escenas seleccionadas, procesa
las transiciones pendientes, actualiza el audio y limpia el estado transitorio
de entrada. Después, `Engine:draw()` dibuja la pila de escenas dentro del
viewport de resolución virtual.

Al cerrar, `Engine:quit()` vacía las escenas, detiene el audio y libera los
recursos restantes.

El motor se construye sobre unos pocos principios:

- Los sistemas tienen una única responsabilidad clara.
- El motor proporciona mecanismos; tu juego define sus propias reglas.
- Las escenas se mantienen independientes de la implementación del gestor de
  escenas.
- Los recursos se comparten y se liberan de forma centralizada.
- Las funcionalidades se añaden solo cuando el juego realmente las necesita.

## Siguientes pasos

1. [Instala Astra 2D y ejecuta el proyecto de ejemplo](/es/getting-started/installation).
2. [Crea tu primer proyecto](/es/getting-started/first-project) con una escena,
   entrada y movimiento.
3. Lee la [descripción general de la arquitectura](/es/architecture/overview)
   para aprender cómo interactúan los módulos del motor.
