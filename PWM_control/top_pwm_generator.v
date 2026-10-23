`timescale 1ns/1ps
/*
 * Módulo generador de señal PWM para control de servomotor
 *
 *  - Periodo: 20 ms (50 Hz)
 *  - Ancho de pulso: 1 ms (0°) a 2 ms (180°)
 *  - Entrada A[3:0]: 16 posiciones (0 = 0°, 15 = 180°, pasos de 12°)
 *  - rst: reinicia el contador y fuerza la salida a 0
 */

// ============================================================
// 1. Módulo TOP
// ============================================================
module top_pwm_generator #(
    parameter CLK_HZ                = 50_000_000, // Reloj de la placa
    parameter CAMBIO_HZ             = 50,         // Frecuencia del servomotor (periodo 20 ms)
    parameter ENTRADAS_ACTIVAS_BAJO = 1,          // 1: switch/botón en "bajo" = 1 lógico (entradas con pull-up)
    parameter RESET_ACTIVO_BAJO     = 1           // 1: el reset se activa con 0 (botón con pull-up)
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] A,
    output reg        pulso = 1'b0
);

    // ------------------------------------------
    // Base de tiempo para el PWM
    // ------------------------------------------
    localparam integer DIV   = CLK_HZ / CAMBIO_HZ;           // 1 000 000 ciclos a 50 MHz = 20 ms
    localparam integer ANCHO = (DIV > 1) ? $clog2(DIV) : 1;  // log2(1 000 000) -> 20 bits

    // ------------------------------------------
    // Acondicionamiento del reset
    // Polaridad + sincronización (2 flip-flops)
    // ------------------------------------------
    wire rst_log = RESET_ACTIVO_BAJO ? ~rst : rst;

    reg rst_s1 = 1'b1, rst_s2 = 1'b1;   // Arranca en reset al encender
    always @(posedge clk) begin
        rst_s1 <= rst_log;
        rst_s2 <= rst_s1;
    end

    wire reset = rst_s2;

    // ------------------------------------------
    // Acondicionamiento de entradas
    // Corrige la polaridad y sincroniza al reloj (2 flip-flops)
    // para evitar metaestabilidad con switches/botones externos.
    // ------------------------------------------
    wire [3:0] entrada_log = ENTRADAS_ACTIVAS_BAJO ? ~A : A;

    reg [3:0] sinc_1 = 4'd0, sinc_2 = 4'd0;
    always @(posedge clk) begin
        sinc_1 <= entrada_log;
        sinc_2 <= sinc_1;
    end

    // ------------------------------------------
    // Conversión de binario a Ton (en ciclos de reloj)
    // ------------------------------------------
    wire [ANCHO-1:0] Ton_nuevo;

    codificador4bits_ciclos #(
        .CLK_HZ(CLK_HZ),
        .ANCHO (ANCHO)
    ) u_cod (
        .bin (sinc_2),
        .duty(Ton_nuevo)
    );

    // ------------------------------------------
    // Contador del periodo y generación del pulso
    // Ton solo se actualiza al inicio de cada periodo,
    // así nunca se generan pulsos "cortados" si A cambia
    // a mitad de un ciclo.
    // ------------------------------------------
    reg [ANCHO-1:0] contador = {ANCHO{1'b0}};
    reg [ANCHO-1:0] Ton      = {ANCHO{1'b0}};

    always @(posedge clk) begin
        if (reset) begin
            contador <= {ANCHO{1'b0}};
            Ton      <= Ton_nuevo;
            pulso    <= 1'b0;
        end else begin
            if (contador == DIV - 1) begin
                contador <= {ANCHO{1'b0}};
                Ton      <= Ton_nuevo;      // Nuevo ancho para el siguiente periodo
            end else begin
                contador <= contador + 1'b1;
            end

            pulso <= (contador < Ton);
        end
    end

endmodule


// ============================================================
// 2. Codificador: 4 bits -> ciclos de reloj en alto
//    bin = 0  -> 1 ms (0°)
//    bin = 15 -> 2 ms (180°)
// ============================================================
module codificador4bits_ciclos #(
    parameter CLK_HZ = 50_000_000,
    parameter ANCHO  = 20
)(
    input  wire [3:0]       bin,
    output wire [ANCHO-1:0] duty
);

    localparam integer T_MIN = CLK_HZ / 2000;   // 0.5 ms -> 25 000 ciclos
    localparam integer T_MAX = CLK_HZ / 400;    // 2 ms ->  125 000 ciclos
    localparam integer RANGO = T_MAX - T_MIN;   //          100 000 ciclos

    // Se usan 32 bits para el producto: 15 * 100 000 = 1 500 000
    wire [31:0] producto = bin * RANGO;
    wire [31:0] ciclos   = T_MIN + (producto / 15);

    assign duty = ciclos[ANCHO-1:0];

endmodule