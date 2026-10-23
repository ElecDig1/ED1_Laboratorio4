`timescale 1ns/1ps
// Testbench: mide periodo y ancho de pulso para las 16 posiciones y prueba el reset
module tb_top_pwm_generator;

    reg        clk = 0;
    reg        rst = 1;          // reset activo en bajo -> 1 = sin reset
    reg  [3:0] A   = 4'hF;       // entradas activas en bajo -> ~0 = posición 0
    wire       pulso;

    top_pwm_generator dut (.clk(clk), .rst(rst), .A(A), .pulso(pulso));

    always #10 clk = ~clk;       // 50 MHz

    time t_sube, t_baja, t_sube_ant;
    integer v, errores = 0;
    real ton_ms, per_ms, esperado;

    task medir_pulso;
        begin
            @(posedge pulso); t_sube_ant = $time;
            @(negedge pulso); t_baja = $time;
            @(posedge pulso); t_sube = $time;
        end
    endtask

    initial begin
        // Reset inicial
        rst = 0; repeat (10) @(posedge clk); rst = 1;

        for (v = 0; v < 16; v = v + 1) begin
            A = ~v[3:0];
            @(posedge pulso);          // deja pasar un periodo para que tome el nuevo Ton
            medir_pulso;
            ton_ms   = (t_baja - t_sube_ant) / 1.0e6;
            per_ms   = (t_sube - t_sube_ant) / 1.0e6;
            esperado = 1.0 + v / 15.0;
            $display("A=%2d  angulo=%5.1f  Ton=%.4f ms (esp. %.4f)  T=%.4f ms",
                     v, v * 12.0, ton_ms, esperado, per_ms);
            if (ton_ms < esperado - 0.001 || ton_ms > esperado + 0.001 || per_ms != 20.0)
                errores = errores + 1;
        end

        // Prueba del reset: a mitad del pulso, la salida debe caer a 0 y el contador reiniciar
        A = ~4'd15;
        @(posedge pulso); #500_000;    // 0.5 ms dentro del pulso
        rst = 0; repeat (5) @(posedge clk);
        if (pulso !== 1'b0) begin $display("ERROR: pulso no cae con reset"); errores = errores + 1; end
        else $display("Reset: salida en 0 durante el reset  OK");
        #1_000_000; rst = 1; t_baja = $time;
        @(posedge pulso);
        $display("Reset: primer pulso %.4f ms despues de soltar reset (sincronizador ~60 ns)",
                 ($time - t_baja) / 1.0e6);

        if (errores == 0) $display("RESULTADO: TODAS LAS PRUEBAS PASARON");
        else              $display("RESULTADO: %0d ERRORES", errores);
        $finish;
    end
endmodule
