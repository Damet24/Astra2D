# Instalación

Astra 2D se ejecuta como código fuente Lua dentro de un juego de [LÖVE](https://love2d.org/). Este repositorio no proporciona un paso de instalación como paquete.

## Requisitos

- **LÖVE 11.5**, la versión utilizada en esta guía. Aquí no se han verificado otras versiones. Instálalo desde [love2d.org](https://love2d.org/) y asegúrate de que el comando `love` esté disponible, o usa la ruta de tu ejecutable de LÖVE.
- **El código fuente del repositorio**, incluido `engine/lib/` y, para el ejemplo, `game/` y sus assets. Git es opcional si descargas el repositorio como archivo comprimido.

LÖVE incluye el entorno de ejecución de Lua. Las bibliotecas Lua del motor están incluidas en `engine/lib/`; los ejemplos no necesitan una instalación separada de Lua ni un gestor de paquetes.

## Ejecutar el proyecto de ejemplo

Clona el repositorio y ejecuta LÖVE con la raíz del repositorio como fuente del juego:

```sh
git clone https://github.com/Damet24/Astra2D.git
cd Astra2D
love .
```

La documentación y el código deben proceder de la misma revisión: el último commit de la rama puede cambiar y la documentación que estás leyendo puede no estar publicada todavía en la rama remota. Usa la revisión correspondiente a tu documentación, tanto con una copia de Git como al descargar un archivo comprimido; no supongas que un clon nuevo ya contiene estas páginas. Puedes comprobar una copia existente con `git rev-parse HEAD`.

En Windows también puedes arrastrar la carpeta del proyecto sobre el ejecutable de LÖVE. Si `love` no está en tu `PATH`, ejecuta el programa instalado con el directorio del proyecto como argumento.

El `main.lua` actual comienza en `mainMenu`. Las asignaciones de `game/config/inputMaps.lua` usan las flechas izquierda y derecha (o la cruceta y el stick izquierdo) para moverse, `Space` o el botón `A` del mando para saltar, y `Escape` o el botón `Start` para pausar. `Return`, `Space`, el clic izquierdo o el botón `A` aceptan las entradas del menú.

## Usar el motor en otro proyecto

Copia el directorio completo `engine/`, incluido `engine/lib/`, al **directorio fuente del juego** junto a `main.lua`. Conserva el nombre `engine`: sus módulos se importan entre sí con el prefijo `engine.`. El sistema de archivos virtual de LÖVE debe poder leer esos archivos; un directorio hermano fuera de la fuente del juego o una ruta Lua local no constituyen una instalación portable.

La estructura más pequeña que se usa en [Tu primer proyecto](/es/getting-started/first-project) es:

```text
my-game/                  # fuente del juego LÖVE
  main.lua
  engine/                 # copia completa, incluido engine/lib/
  game/
    config/
      inputMaps.lua
    scenes/
      hello.lua
```

La guía proporciona todos los archivos necesarios para esta estructura. Un archivo de definiciones de recursos es opcional; el ejemplo no necesita assets. Ejecuta `love .` desde `my-game/`, o pasa ese directorio a LÖVE desde otra ubicación.

## Configuración del motor

`Engine.new(config)` construye los servicios; no carga la escena. Los campos obligatorios son `initialScene`, una cadena no vacía, e `inputMaps`, una tabla de acciones (puede ser `{}`; el motor la reenvía sin validar la forma de las acciones). Los demás campos son opcionales:

| Campo | Valores por defecto y comportamiento |
| --- | --- |
| `scenesPath` | `"game.scenes"`; prefijo no vacío de módulos Lua. |
| `resourceDefinitions` | `{}`; definiciones indexadas por ID de recurso. |
| `resourceLoaders` | Cargadores integrados para `image`, `sound` y `font`; una tabla proporcionada sustituye a los predeterminados. |
| `window` | Si se omite, el motor no cambia el modo de ventana de LÖVE. Si se proporciona, `width` y `height` son enteros positivos obligatorios; por defecto `fullscreen = false`, `resizable = true` y `vsync = true`. |
| `rendering` | Por defecto `width = 1280`, `height = 720`, `pixelPerfect = false`, `backgroundColor = { 0, 0, 0, 1 }` en la resolución lógica. Las dimensiones son enteros positivos. |
| `audio` | `masterVolume`, `musicVolume` y `sfxVolume` tienen cada uno el valor predeterminado `1.0`. |

`backgroundColor` es un array contiguo RGB o RGBA con componentes entre `0` y `1`; el alfa omitido es `1`. `pixelPerfect = true` usa escalado entero y filtrado nearest; una ventana menor que la resolución lógica puede quedar recortada. Consulta la [arquitectura de Engine](/es/architecture/modules/engine) para más detalles de validación y ciclo de vida.

Con el `scenesPath` predeterminado, `initialScene = "hello"` carga `game/scenes/hello.lua`; `levels.level01` carga `game/scenes/levels/level01.lua`. El módulo debe devolver una tabla con una función `new(context)` que devuelva una escena con los métodos de ciclo de vida utilizados por `SceneManager`. [Tu primer proyecto](/es/getting-started/first-project) incluye un ejemplo completo; el motor instala los callbacks de entrada de LÖVE cuando el juego llama a `Engine:load()`.

## Empaquetar el juego

Un archivo `.love` es un ZIP cuya **raíz** contiene `main.lua`, `engine/` y los archivos del juego, sin una carpeta `my-game/` que los envuelva. Usa un nombre nuevo para cada compilación: actualizar un ZIP existente puede conservar entradas eliminadas de la fuente. Por ejemplo, desde `my-game/` con el comando `zip` disponible:

```sh
if [ -e my-game.love ] || [ -L my-game.love ]; then
    printf '%s\n' 'my-game.love ya existe; elige otro nombre.' >&2
else
    zip -r my-game.love main.lua engine game && love my-game.love
fi
```

La comprobación también rechaza enlaces simbólicos rotos. Si el nombre está ocupado, elige otro nombre en ambos comandos; este ejemplo no elimina ni sobrescribe la ruta existente.

Incluye los demás archivos que use el juego (por ejemplo, `conf.lua` o assets) en sus rutas correspondientes. No dependas de un directorio `engine/` fuera del archivo. Consulta la [guía de distribución de LÖVE](https://love2d.org/wiki/Game_Distribution) para el empaquetado específico de cada plataforma.

## Licencias

El código propio de Astra 2D se distribuye bajo la licencia MIT incluida en el archivo `LICENSE` de la raíz del repositorio. Las bibliotecas incluidas tienen sus propios avisos, entre ellos `engine/lib/shove/LICENSE` y el aviso en `engine/lib/hump/camera.lua`; conserva y cumple los términos de terceros aplicables. Verifica los permisos de los assets de terceros antes de redistribuirlos.

## Solución de problemas

- **`module 'engine.engine' not found`:** pasa a LÖVE el directorio o archivo `.love` que contiene tanto `main.lua` como `engine/`; conserva `engine/lib/`.
- **Fallan las consultas de entrada:** pasa `inputMaps` a `Engine.new`, aunque sea `{}`. El motor reenvía la tabla sin validarla; cada acción es una tabla con secciones opcionales `keys`, `mouse` y `gamepad`, y los nombres de acción desconocidos devuelven `false`.
- **`Failed to load scene '...'`:** revisa el prefijo `scenesPath`, el identificador de escena, el nombre y las mayúsculas exactas del archivo y que su módulo devuelva una tabla con `new`. El error también puede contener un fallo dentro del módulo de escena.
- **Falla la creación de la ventana:** revisa el modo solicitado y el entorno gráfico. Los sistemas sin pantalla necesitan un backend gráfico offscreen adecuado; no disponen de una ventana normal.

## Siguientes pasos

Continúa con [Tu primer proyecto](/es/getting-started/first-project) para construir una escena completa con entrada y movimiento.
