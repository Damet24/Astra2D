3. Falta manejar la pérdida de foco

Si el usuario cambia de ventana mientras mantiene una tecla pulsada, puede quedar un estado de entrada sostenido si no llega el evento de liberación.

Implementaría un mecanismo para limpiar los estados temporales y sostenidos cuando LÖVE notifique la pérdida de foco. Esto también merece un test.

4. La integración con Tiled todavía requiere trabajo manual

El renderizador soporta capas de tiles y su orden de dibujo, pero las colisiones de los objetos de Tiled se construyen manualmente en las escenas.

No es necesariamente un problema: separar el renderizado de la física tiene sentido. Pero sería conveniente tener utilidades para convertir las capas de objetos en entidades físicas, sin obligar a repetir ese código en cada nivel.
