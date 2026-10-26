# Generador PWM para servomotor

Módulo en Verilog que genera la señal PWM para controlar la posición de un servomotor desde 4 switches. Forma parte del proyecto FPGA_PONG.

## Funcionamiento

- **Periodo:** 20 ms (50 Hz).
- **Ancho de pulso:** de `PULSO_MIN_US` (0°) a `PULSO_MAX_US` (180°). Por defecto, 0.5 ms a 2.5 ms.
- **Entrada `A[3:0]`:** 16 posiciones, de `0000` (0°) a `1111` (180°), en pasos de 12°.
- **El ancho de pulso se actualiza al inicio de cada periodo,** así que cambiar los switches nunca produce un pulso cortado.
- **Las entradas y el reset se sincronizan con 2 flip-flops** para evitar metaestabilidad.

## Puertos

| Puerto  | Dirección | Descripción                                    |
|---------|-----------|------------------------------------------------|
| `clk`   | entrada   | Reloj de la placa (50 MHz por defecto)         |
| `rst`   | entrada   | Reset: reinicia el contador y pone la salida en 0 |
| `A[3:0]`| entrada   | Posición deseada del servo                     |
| `pulso` | salida    | Señal PWM hacia el cable de señal del servo    |

## Parámetros

| Parámetro               | Por defecto  | Descripción                                          |
|-------------------------|--------------|------------------------------------------------------|
| `CLK_HZ`                | 50_000_000   | Frecuencia del reloj de la placa                     |
| `CAMBIO_HZ`             | 50           | Frecuencia del PWM (periodo de 20 ms)                |
| `ENTRADAS_ACTIVAS_BAJO` | 1            | 1 si los switches dan 0 lógico cuando están activos  |
| `RESET_ACTIVO_BAJO`     | 1            | 1 si el reset se activa con 0 (botón con pull-up)    |
| `PULSO_MIN_US`          | 500          | Ancho de pulso para 0°, en µs                        |
| `PULSO_MAX_US`          | 2500         | Ancho de pulso para 180°, en µs                      |

## Archivos

- `top_pwm_generator.v`: módulo principal y codificador de 4 bits a ciclos de reloj.
- `tb_top_pwm_generator.v`: testbench que mide el periodo y el ancho de pulso de las 16 posiciones y prueba el reset.

## Simulación

Con Icarus Verilog y GTKWave:

```
iverilog -o sim tb_top_pwm_generator.v top_pwm_generator.v
vvp sim
gtkwave pwm.vcd
```

La simulación tarda cerca de un minuto y termina con `RESULTADO: TODAS LAS PRUEBAS PASARON`.

## Conexión del servo

- **Alimentación:** usa una fuente externa de 4.8–6 V, no el pin de 5 V de la FPGA.
- **Tierra común:** une la GND de la fuente con la GND de la FPGA.
- **Señal:** conecta `pulso` al cable de señal del servo. La salida de 3.3 V de la FPGA funciona con la mayoría de los servos.

## Calibración

Si el servo no llega a los extremos, amplía `PULSO_MIN_US` o `PULSO_MAX_US`. Si zumba o se fuerza en un extremo, está chocando con su tope mecánico: reduce el rango, por ejemplo a 600–2400 µs.



## Simulaciones

### Simulación 1
![Simulación 1](1.png)
![Simulación 1](1.1.png)

### Simulación 2
![Simulación 2](2.png)
![Simulación 1](2.2.png)

### Simulación 3
![Simulación 3](3.png)
![Simulación 3](3.3.png)

