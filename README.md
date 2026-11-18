# Astra 2D

Astra 2D es un motor modular para crear juegos 2D con Lua y [LÖVE](https://love2d.org/). Proporciona herramientas para organizar escenas, entidades, recursos y renderizado, mientras que las reglas y el contenido de cada juego se definen en sus propias escenas y sistemas.

El repositorio incluye el código del motor en `engine/`, un juego de prueba en `game/` y un ejemplo independiente en `examples/collect/`.

## Características

- **Escenas:** pila de escenas, transiciones diferidas y callbacks de ciclo de vida.
- **Entidades y sistemas (ECS):** componentes, consultas, sistemas ordenados y eventos.
- **Recursos:** carga, reutilización y liberación de imágenes, sonidos y fuentes por consumidor.
- **Entrada:** acciones configurables con teclado, ratón y mando (botones y ejes), con consultas de estado mantenido, pulsado y soltado.
- **Audio:** reproducción de música y efectos mediante un gestor compartido.
- **Cámaras y renderizado:** vistas de mundo, resolución lógica, escalado y dibujo por capas.
- **Física:** integración con `love.physics` mediante cuerpos, colisionadores rectangulares y sistemas ECS.
- **Mapas de Tiled:** renderizado de capas de tiles exportadas a Lua; las colisiones se crean por separado.

## Requisitos

- [LÖVE 11.5](https://love2d.org/), la versión utilizada en la documentación y las pruebas del proyecto. Otras versiones no han sido verificadas.
- El código fuente del repositorio, incluido `engine/lib/` y, para ejecutar el juego de prueba, el directorio `game/` con sus recursos.
- Para editar mapas, [Tiled](https://www.mapeditor.org/) es opcional. Para desarrollar o compilar el sitio de documentación, se necesitan Node.js y npm; no son necesarios para ejecutar el juego.

LÖVE incluye el entorno Lua; no es necesario instalar Lua por separado para ejecutar los ejemplos.

## Ejecutar el juego de prueba

Desde la raíz de una copia del repositorio:

```sh
love .
```

Si `love` no está en el `PATH`, ejecuta el programa de LÖVE instalado y pásale la ruta de la carpeta del repositorio. El `main.lua` actual inicia `levels.level01`.

Controles del juego de prueba: flecha izquierda o **A** para moverse a la izquierda; flecha derecha o **E** para moverse a la derecha; **espacio** para saltar y **Esc** para pausar. Para ejecutar el ejemplo independiente Collect, consulta sus [instrucciones](docs/es/examples/index.md).

Para usar el motor en otro proyecto LÖVE, copia `engine/` completo, incluido `engine/lib/`, dentro del directorio fuente del juego junto a su `main.lua`. La guía [Tu primer proyecto](docs/es/getting-started/first-project.md) muestra una configuración y una escena completas.

## Documentación

La documentación completa está publicada en [GitHub Pages](https://damet24.github.io/Astra2D/); también puedes leerla directamente en [español](https://damet24.github.io/Astra2D/es/). Las fuentes del sitio están en `docs/`.

- [Instalación](docs/es/getting-started/installation.md)
- [Tu primer proyecto](docs/es/getting-started/first-project.md)
- [Arquitectura](docs/es/architecture/overview.md)
- [Guías](docs/es/guides/index.md)
- [Referencia de API](docs/es/api/index.md)
- [Ejemplos](docs/es/examples/index.md)

## Licencias y créditos

El código propio de Astra 2D está disponible bajo la [licencia MIT](LICENSE).

La cámara utiliza [HUMP](https://github.com/vrld/hump), de Matthias Richter, mediante un adaptador; su aviso de derechos y licencia está en `engine/lib/hump/camera.lua`. El viewport utiliza Shove, cuya licencia está en `engine/lib/shove/LICENSE`. Las bibliotecas y los recursos de terceros pueden tener sus propios términos: consérvalos y verifica los permisos de los assets antes de redistribuirlos.
