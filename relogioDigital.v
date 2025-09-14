module counter(
    input clk,
    input reset,
    input enable,               // Sinal de controle para congelar o relógio
    input [4:0] horas_ajustado, // Novo valor de horas ajustado
    input [5:0] minutos_ajustado, // Novo valor de minutos ajustado
    input ajuste_horas,         // Sinal para saber se horas estão sendo ajustadas
    input ajuste_minutos,       // Sinal para saber se minutos estão sendo ajustados
    output reg [5:0] segundos,  // 0-59
    output reg [5:0] minutos,   // 0-59
    output reg [4:0] horas,     // 0-23
    output reg [7:0] leds,
    output blk       
);
    assign blk = 1;
    always @(posedge clk) begin
        if (reset) begin
            // Reseta o relógio
            segundos <= 0;
            minutos <= 0;
            horas <= 0;
            leds <= 8'b0;
        end else if (ajuste_horas) begin
            // Ajusta as horas
            horas <= horas_ajustado;
        end else if (ajuste_minutos) begin
            // Ajusta os minutos
            minutos <= minutos_ajustado;
        end else if (enable) begin
            // Se o relógio está em execução, conta o tempo normalmente
            if (segundos == 59) begin
                segundos <= 0;
                if (minutos == 59) begin
                    minutos <= 0;
                    if (horas == 23) begin
                        horas <= 0;
                    end else begin
                        horas <= horas + 1;
                    end
                end else begin
                    minutos <= minutos + 1;
                end
            end else begin
                segundos <= segundos + 1;
            end
        end
        
        // Atualiza os LEDs com o valor dos segundos
        leds <= segundos;
    end
endmodule



module seven_segment_converter(
    input [3:0] numero,
    output reg [6:0] seg
);
    always @(*) begin
        case (numero)
            4'b0000: seg = 7'b0111111; // 0
            4'b0001: seg = 7'b0000110; // 1
            4'b0010: seg = 7'b1011011; // 2
            4'b0011: seg = 7'b1001111; // 3
            4'b0100: seg = 7'b1100110; // 4
            4'b0101: seg = 7'b1101101; // 5
            4'b0110: seg = 7'b1111101; // 6
            4'b0111: seg = 7'b0000111; // 7
            4'b1000: seg = 7'b1111111; // 8
            4'b1001: seg = 7'b1100111; // 9
            default: seg = 7'b0000000; // Apagar
        endcase
    end
endmodule


module digital_clock(
    input clk,
    input reset,
    input btn0,  // Botão para alternar entre os estados
    input btn1,  // Botão para incrementar hora ou minuto, dependendo do estado
    output [6:0] display_horas_d,
    output [6:0] display_horas_u,
    output [6:0] display_minutos_d,
    output [6:0] display_minutos_u,
    output [7:0] leds,  //LEDs para representar os segundos
    output blk) ;
    // Definir os estados
    parameter NORMAL = 2'b00;        // Relógio rodando normalmente
    parameter SET_HORAS = 2'b01;     // Ajuste de horas
    parameter SET_MINUTOS = 2'b10;   // Ajuste de minutos

    reg [1:0] estado;  // Estado atual
    wire [5:0] segundos;      // Segundos
    reg [5:0] minutos_ajustado; // Minutos ajustáveis
    reg [4:0] horas_ajustado;   // Horas ajustáveis
    reg enable_relogio;

    reg [5:0] minutos_contador;  // Minutos reais do contador
    reg [4:0] horas_contador;    // Horas reais do contador

    // Registradores para detectar borda de subida dos botões
    reg btn0_ultimo, btn1_ultimo;

    // Instância do contador para os segundos, minutos e horas
    counter cnt(
        .clk(clk),
        .reset(reset),
        .enable(enable_relogio),
        .segundos(segundos),
        .minutos(minutos_contador),
        .horas(horas_contador),
        .leds(leds),
        .horas_ajustado(horas_ajustado),  // Conectado para ajuste de horas
        .minutos_ajustado(minutos_ajustado), // Conectado para ajuste de minutos
        .ajuste_horas(estado == SET_HORAS),  // Ativo quando ajustando horas
        .ajuste_minutos(estado == SET_MINUTOS),
        .blk(blk)
    );

    // Controle de estado e ajuste
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado <= NORMAL;
            horas_ajustado <= 0;
            minutos_ajustado <= 0;
            enable_relogio <= 1;  // Relógio rodando no estado normal
            btn0_ultimo <= 0;
            btn1_ultimo <= 0;
        end else begin
            // Detectar borda de subida dos botões
            if (btn0 && !btn0_ultimo) begin
                // btn0 foi pressionado (borda de subida)
                case (estado)
                    NORMAL: begin
                        estado <= SET_HORAS;
                        enable_relogio <= 0;  // Congela o relógio
                    end
                    SET_HORAS: begin
                        estado <= SET_MINUTOS;
                    end
                    SET_MINUTOS: begin
                        estado <= NORMAL;
                        enable_relogio <= 1;  // Reinicia o relógio
                    end
                endcase
            end

            if (btn1 && !btn1_ultimo) begin
                // btn1 foi pressionado (borda de subida)
                case (estado)
                    SET_HORAS: begin
                        if (horas_ajustado == 23) begin
                            horas_ajustado <= 0;
                        end else begin
                            horas_ajustado <= horas_ajustado + 1;
                        end
                    end
                    SET_MINUTOS: begin
                        if (minutos_ajustado == 59) begin
                            minutos_ajustado <= 0;
                        end else begin
                            minutos_ajustado <= minutos_ajustado + 1;
                        end
                    end
                endcase
            end

            // Atualiza o valor anterior dos botões
            btn0_ultimo <= btn0;
            btn1_ultimo <= btn1;
        end
    end

    // Conversores de 7 segmentos para exibir horas e minutos
    seven_segment_converter converter_horas_u (
        .numero(horas_contador % 10),
        .seg(display_horas_u)
    );

    seven_segment_converter converter_horas_d (
        .numero((horas_contador / 10) % 10),
        .seg(display_horas_d)
    );

    seven_segment_converter converter_minutos_u (
        .numero(minutos_contador % 10),
        .seg(display_minutos_u)
    );

    seven_segment_converter converter_minutos_d (
        .numero((minutos_contador / 10) % 10),
        .seg(display_minutos_d)
    );
endmodule
