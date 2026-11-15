# Ejemplos

## Collect

Un pequeño juego de recogida con vista superior: recorre un campo más grande, recoge los tres puntos amarillos y reinicia al terminar. Combina el `Engine`, la pila de escenas, acciones de entrada, entidades ECS y el sistema de movimiento, una cámara que sigue al jugador y una fuente gestionada como recurso. La escena de pausa se dibuja sobre el campo y detiene su actualización. Todo se dibuja con primitivas de LÖVE, sin recursos externos.

Código: `examples/collect/`. El directorio por sí solo **no** es un proyecto LÖVE ejecutable: LÖVE también debe encontrar `engine/` en el sistema de archivos de su proyecto. El runner siguiente reúne ambos en un proyecto temporal, sin modificar ni copiar permanentemente el motor en el repositorio.

### Ejecutar en Linux o macOS

Instala LÖVE 11.5 y asegúrate de que `love` esté disponible en `PATH`. Desde la raíz del repositorio:

```sh
sh examples/run.sh collect
```

Para usar un ejecutable concreto, indica su ruta en `LOVE_BIN`. Por ejemplo, en Linux con un AppImage que no pueda montarse:

```sh
APPIMAGE_EXTRACT_AND_RUN=1 LOVE_BIN=/ruta/a/love.AppImage sh examples/run.sh collect
```

El runner de shell POSIX también funciona desde otro directorio si se proporciona la ruta a `examples/run.sh`. Necesita `mktemp` y `cp`; crea un directorio nuevo bajo `TMPDIR` (o `/tmp`) y elimina solo ese directorio al terminar LÖVE. En macOS, configura `LOVE_BIN` de la misma forma si LÖVE no está en `PATH`.

### Controles

- **WASD** o **flechas**: mover (la velocidad diagonal está limitada).
- **Esc**: pausar o reanudar.
- **R**: reiniciar el campo cuando no está en pausa.
- Cierra la ventana para salir.

### Proyecto manual o paquete `.love`

Otra opción es crear, desde la raíz del repositorio, un directorio **nuevo** llamado `my-astra-collect` (el comando se detiene si ya existe), copiar el motor y el ejemplo dentro y ejecutarlo:

```sh
mkdir my-astra-collect && cp -R engine my-astra-collect/engine && cp -R examples/collect/. my-astra-collect/ && love my-astra-collect
```

Para crear un archivo distribuible, con la utilidad `zip` instalada, usa un nombre nuevo (este comando rechaza archivos y enlaces simbólicos existentes):

```sh
[ ! -e collect.love ] && [ ! -L collect.love ] && (cd my-astra-collect && zip -r ../collect.love .) && love collect.love
```

`main.lua`, `conf.lua`, `scenes/` y `engine/` deben estar en la raíz del archivo, no dentro de un directorio adicional. En Windows, crea una carpeta nueva con el explorador, copia dentro el contenido de `examples/collect/` y la carpeta `engine/`, y arrastra la carpeta sobre LÖVE. Para empaquetarlo, comprime ese contenido y cambia la extensión del archivo a `.love`. Elimina el directorio o el archivo manual solo si ya no lo necesitas.

### Prueba smoke sin pantalla

La prueba comprueba movimiento, los tres objetos, pausa/reanudación, dibujo, reinicio y liberación de recursos, y termina automáticamente con código 0 si pasa o distinto de cero si falla. En Linux, con una versión de SDL que admita el controlador de vídeo `offscreen` y OpenGL por software:

```sh
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy LIBGL_ALWAYS_SOFTWARE=1 sh examples/smoke.sh
```

Configura `LOVE_BIN` y, si usas un AppImage que lo necesite, `APPIMAGE_EXTRACT_AND_RUN=1` como antes. El ejemplo desactiva el audio y la prueba no necesita servidor de pantalla. Para imponer un límite externo de tiempo en Linux, ejecuta:

```sh
timeout 60s env SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy LIBGL_ALWAYS_SOFTWARE=1 sh examples/smoke.sh
```

En macOS, GNU coreutils proporciona `gtimeout` en lugar de `timeout`. La disponibilidad de `offscreen` depende de la instalación local de SDL/OpenGL.
