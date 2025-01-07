module KEYPAD4x4 (
    input clk,
    input reset,
    input [3:0] keypad_row,
    input [3:0] keypad_col,
    output reg [3:0] category,
    output reg [9:0] new_value,
    output reg start,
    output reg accept,
    output reg backspace,
    input [9:0] PARAM_SOIL_DRY,
    input [9:0] PARAM_SOIL_MOIST,
    input [9:0] PARAM_SOIL_WET,
    input [9:0] PARAM_TEMP_COLD,
    input [9:0] PARAM_TEMP_WARM,
    input [9:0] PARAM_TEMP_HOT,
    input [9:0] PARAM_RAIN_NO,
    input [9:0] PARAM_RAIN_YES,
    output reg updated,
    output reg [9:0] NEW_PARAM_SOIL_DRY,
    output reg [9:0] NEW_PARAM_SOIL_MOIST,
    output reg [9:0] NEW_PARAM_SOIL_WET,
    output reg [9:0] NEW_PARAM_TEMP_COLD,
    output reg [9:0] NEW_PARAM_TEMP_WARM,
    output reg [9:0] NEW_PARAM_TEMP_HOT,
    output reg [9:0] NEW_PARAM_RAIN_NO,
    output reg [9:0] NEW_PARAM_RAIN_YES,
    output reg update_soil_dry,
    output reg update_soil_moist,
    output reg update_soil_wet,
    output reg update_temp_cold,
    output reg update_temp_warm,
    output reg update_temp_hot,
    output reg update_rain_no,
    output reg update_rain_yes
);

    reg [3:0] key_map;
    reg [3:0] state;
    reg [9:0] buffer;

    localparam IDLE = 4'b0000;
    localparam SELECT_CATEGORY = 4'b0001;
    localparam INPUT_VALUE = 4'b0010;
    localparam CONFIRM_UPDATE = 4'b0011;

    always @(*) begin
        case ({keypad_row, keypad_col})
            8'b1110_1110: key_map = 4'h1;
            8'b1110_1101: key_map = 4'h2;
            8'b1110_1011: key_map = 4'h3;
            8'b1110_0111: key_map = 4'hA;
            8'b1101_1110: key_map = 4'h4;
            8'b1101_1101: key_map = 4'h5;
            8'b1101_1011: key_map = 4'h6;
            8'b1101_0111: key_map = 4'hB;
            8'b1011_1110: key_map = 4'h7;
            8'b1011_1101: key_map = 4'h8;
            8'b1011_1011: key_map = 4'h9;
            8'b1011_0111: key_map = 4'hC;
            8'b0111_1110: key_map = 4'h0;
            8'b0111_1101: key_map = 4'hF;
            default: key_map = 4'b0;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            category <= 4'd0;
            buffer <= 10'd0;
            updated <= 1'b0;
            new_value <= 10'd0;
            start <= 1'b0;
            accept <= 1'b0;
            backspace <= 1'b0;
            update_soil_dry <= 1'b0;
            update_soil_moist <= 1'b0;
            update_soil_wet <= 1'b0;
            update_temp_cold <= 1'b0;
            update_temp_warm <= 1'b0;
            update_temp_hot <= 1'b0;
            update_rain_no <= 1'b0;
            update_rain_yes <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    start <= 1'b0;
                    if (key_map == 4'hA) begin
                        buffer <= 10'd0;
                        start <= 1'b1;
                        state <= SELECT_CATEGORY;
                    end
                end

                SELECT_CATEGORY: begin
                    if (key_map >= 4'h1 && key_map <= 4'h8) begin
                        category <= key_map;
                        buffer <= 10'd0;
                        state <= INPUT_VALUE;
                    end
                end

                INPUT_VALUE: begin
                    backspace <= 1'b0;
                    if (key_map == 4'hF) begin
                        accept <= 1'b1;
                        state <= CONFIRM_UPDATE;
                    end else if (key_map == 4'hB) begin
                        buffer <= buffer / 10;
                        backspace <= 1'b1;
                    end else if (key_map <= 4'h9) begin
                        if (buffer < 1023) begin
                            buffer <= (buffer * 10) + key_map;
                        end
                    end
                end

                CONFIRM_UPDATE: begin
                    case (category)
                        4'h1: if (buffer > 0 && buffer < PARAM_SOIL_MOIST) begin
                            NEW_PARAM_SOIL_DRY <= buffer;
                            update_soil_dry <= 1'b1; updated <= 1'b1;
                        end
                        4'h2: if (buffer > PARAM_SOIL_DRY && buffer < PARAM_SOIL_WET) begin
                            NEW_PARAM_SOIL_MOIST <= buffer;
                            update_soil_moist <= 1'b1; updated <= 1'b1;
                        end
                        4'h3: if (buffer > PARAM_SOIL_MOIST && buffer <= 1023) begin
                            NEW_PARAM_SOIL_WET <= buffer;
                            update_soil_wet <= 1'b1; updated <= 1'b1;
                        end
                        4'h4: if (buffer > 0 && buffer < PARAM_TEMP_WARM) begin
                            NEW_PARAM_TEMP_COLD <= buffer;
                            update_temp_cold <= 1'b1; updated <= 1'b1;
                        end
                        4'h5: if (buffer > PARAM_TEMP_COLD && buffer < PARAM_TEMP_HOT) begin
                            NEW_PARAM_TEMP_WARM <= buffer;
                            update_temp_warm <= 1'b1; updated <= 1'b1;
                        end
                        4'h6: if (buffer > PARAM_TEMP_WARM && buffer <= 1023) begin
                            NEW_PARAM_TEMP_HOT <= buffer;
                            update_temp_hot <= 1'b1; updated <= 1'b1;
                        end
                        4'h7: if (buffer > 0 && buffer < PARAM_RAIN_YES) begin
                            NEW_PARAM_RAIN_NO <= buffer;
                            update_rain_no <= 1'b1; updated <= 1'b1;
                        end
                        4'h8: if (buffer > PARAM_RAIN_NO && buffer <= 1023) begin
                            NEW_PARAM_RAIN_YES <= buffer;
                            update_rain_yes <= 1'b1; updated <= 1'b1;
                        end
                    endcase
                    new_value <= buffer;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
