module FUZZIFIKASI #(
    parameter DATA_WIDTH = 10
)(
    input clk,
    input reset,
    input [9:0] new_soil_dry,
    input [9:0] new_soil_moist,
    input [9:0] new_soil_wet,
    input [9:0] new_temp_cold,
    input [9:0] new_temp_warm,
    input [9:0] new_temp_hot,
    input [9:0] new_rain_no,
    input [9:0] new_rain_yes,
    input update_soil_dry,
    input update_soil_moist,
    input update_soil_wet,
    input update_temp_cold,
    input update_temp_warm,
    input update_temp_hot,
    input update_rain_no,
    input update_rain_yes,
    input [DATA_WIDTH-1:0] soil_digital,
    input [DATA_WIDTH-1:0] dht11_digital,
    input [DATA_WIDTH-1:0] rain_digital,  
    output reg [7:0] irrigation_time,
    output reg rain_present,
    output reg [9:0] PARAM_SOIL_DRY,
    output reg [9:0] PARAM_SOIL_MOIST,
    output reg [9:0] PARAM_SOIL_WET,
    output reg [9:0] PARAM_TEMP_COLD,
    output reg [9:0] PARAM_TEMP_WARM,
    output reg [9:0] PARAM_TEMP_HOT,
    output reg [9:0] PARAM_RAIN_NO,
    output reg [9:0] PARAM_RAIN_YES
);

    localparam [9:0] DEFAULT_SOIL_DRY = 10'd400;
    localparam [9:0] DEFAULT_SOIL_MOIST = 10'd600;
    localparam [9:0] DEFAULT_SOIL_WET = 10'd800;
    localparam [9:0] DEFAULT_TEMP_COLD = 10'd300;
    localparam [9:0] DEFAULT_TEMP_WARM = 10'd500;
    localparam [9:0] DEFAULT_TEMP_HOT = 10'd700;
    localparam [9:0] DEFAULT_RAIN_NO = 10'd100;
    localparam [9:0] DEFAULT_RAIN_YES = 10'd400;

    reg [DATA_WIDTH-1:0] mu_soil_dry, mu_soil_moist, mu_soil_wet;
    reg [DATA_WIDTH-1:0] mu_temp_cold, mu_temp_warm, mu_temp_hot;
    reg [DATA_WIDTH-1:0] mu_rain_no, mu_rain_yes;
    reg [DATA_WIDTH-1:0] rule[17:0];
    reg [7:0] irrigation_values[17:0];
    reg [DATA_WIDTH+7:0] numerator, denominator;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PARAM_SOIL_DRY <= DEFAULT_SOIL_DRY;
            PARAM_SOIL_MOIST <= DEFAULT_SOIL_MOIST;
            PARAM_SOIL_WET <= DEFAULT_SOIL_WET;
            PARAM_TEMP_COLD <= DEFAULT_TEMP_COLD;
            PARAM_TEMP_WARM <= DEFAULT_TEMP_WARM;
            PARAM_TEMP_HOT <= DEFAULT_TEMP_HOT;
            PARAM_RAIN_NO <= DEFAULT_RAIN_NO;
            PARAM_RAIN_YES <= DEFAULT_RAIN_YES;

            mu_soil_dry <= 0;
            mu_soil_moist <= 0;
            mu_soil_wet <= 0;
            mu_temp_cold <= 0;
            mu_temp_warm <= 0;
            mu_temp_hot <= 0;
            mu_rain_no <= 0;
            mu_rain_yes <= 0;
            
            numerator <= 0;
            denominator <= 0;
            irrigation_time <= 0;
            rain_present <= 0;
        end else begin
            if (update_soil_dry) PARAM_SOIL_DRY <= new_soil_dry;
            if (update_soil_moist) PARAM_SOIL_MOIST <= new_soil_moist;
            if (update_soil_wet) PARAM_SOIL_WET <= new_soil_wet;
            if (update_temp_cold) PARAM_TEMP_COLD <= new_temp_cold;
            if (update_temp_warm) PARAM_TEMP_WARM <= new_temp_warm;
            if (update_temp_hot) PARAM_TEMP_HOT <= new_temp_hot;
            if (update_rain_no) PARAM_RAIN_NO <= new_rain_no;
            if (update_rain_yes) PARAM_RAIN_YES <= new_rain_yes;

            if (soil_digital <= PARAM_SOIL_DRY) begin
                mu_soil_dry <= 1023; mu_soil_moist <= 0; mu_soil_wet <= 0;
            end else if (soil_digital <= PARAM_SOIL_MOIST) begin
                mu_soil_dry <= ((PARAM_SOIL_MOIST - soil_digital) * 1023) / (PARAM_SOIL_MOIST - PARAM_SOIL_DRY);
                mu_soil_moist <= ((soil_digital - PARAM_SOIL_DRY) * 1023) / (PARAM_SOIL_MOIST - PARAM_SOIL_DRY);
                mu_soil_wet <= 0;
            end else if (soil_digital <= PARAM_SOIL_WET) begin
                mu_soil_dry <= 0;
                mu_soil_moist <= ((PARAM_SOIL_WET - soil_digital) * 1023) / (PARAM_SOIL_WET - PARAM_SOIL_MOIST);
                mu_soil_wet <= ((soil_digital - PARAM_SOIL_MOIST) * 1023) / (PARAM_SOIL_WET - PARAM_SOIL_MOIST);
            end else begin
                mu_soil_dry <= 0; mu_soil_moist <= 0; mu_soil_wet <= 1023;
            end

            if (dht11_digital <= PARAM_TEMP_COLD) begin
                mu_temp_cold <= 1023; mu_temp_warm <= 0; mu_temp_hot <= 0;
            end else if (dht11_digital <= PARAM_TEMP_WARM) begin
                mu_temp_cold <= ((PARAM_TEMP_WARM - dht11_digital) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
                mu_temp_warm <= ((dht11_digital - PARAM_TEMP_COLD) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
                mu_temp_hot <= 0;
            end else if (dht11_digital <= PARAM_TEMP_HOT) begin
                mu_temp_cold <= 0;
                mu_temp_warm <= ((PARAM_TEMP_HOT - dht11_digital) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
                mu_temp_hot <= ((dht11_digital - PARAM_TEMP_WARM) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
            end else begin
                mu_temp_cold <= 0; mu_temp_warm <= 0; mu_temp_hot <= 1023;
            end

            if (rain_digital <= PARAM_RAIN_NO) begin
                mu_rain_no <= 1023; mu_rain_yes <= 0;
            end else if (rain_digital <= PARAM_RAIN_YES) begin
                mu_rain_no <= ((PARAM_RAIN_YES - rain_digital) * 1023) / (PARAM_RAIN_YES - PARAM_RAIN_NO);
                mu_rain_yes <= ((rain_digital - PARAM_RAIN_NO) * 1023) / (PARAM_RAIN_YES - PARAM_RAIN_NO);
            end else begin
                mu_rain_no <= 0; mu_rain_yes <= 1023;
            end

            irrigation_values[0] <= 8'd0;
            irrigation_values[1] <= 8'd0;
            irrigation_values[2] <= 8'd10;
            irrigation_values[3] <= 8'd0;
            irrigation_values[4] <= 8'd45;
            irrigation_values[5] <= 8'd0;
            irrigation_values[6] <= 8'd0;
            irrigation_values[7] <= 8'd0;
            irrigation_values[8] <= 8'd10;
            irrigation_values[9] <= 8'd0;
            irrigation_values[10] <= 8'd45;
            irrigation_values[11] <= 8'd0;
            irrigation_values[12] <= 8'd0;
            irrigation_values[13] <= 8'd0;
            irrigation_values[14] <= 8'd10;
            irrigation_values[15] <= 8'd0;
            irrigation_values[16] <= 8'd30;
            irrigation_values[17] <= 8'd0;

            numerator <= 0;
            denominator <= 0;

            for (i = 0; i < 18; i = i + 1) begin
                rule[i] <= 0;
                case (i)
	    	    0: rule[i] <= (mu_soil_dry < mu_temp_cold) ? ((mu_soil_dry < mu_rain_no) ? mu_soil_dry : mu_rain_no) : ((mu_temp_cold < mu_rain_no) ? mu_temp_cold : mu_rain_no);
                    1: rule[i] <= (mu_soil_dry < mu_temp_cold) ? ((mu_soil_dry < mu_rain_yes) ? mu_soil_dry : mu_rain_yes) : ((mu_temp_cold < mu_rain_yes) ? mu_temp_cold : mu_rain_yes);
                    2: rule[i] <= (mu_soil_dry < mu_temp_warm) ? ((mu_soil_dry < mu_rain_no) ? mu_soil_dry : mu_rain_no) : ((mu_temp_warm < mu_rain_no) ? mu_temp_warm : mu_rain_no);
                    3: rule[i] <= (mu_soil_dry < mu_temp_warm) ? ((mu_soil_dry < mu_rain_yes) ? mu_soil_dry : mu_rain_yes) : ((mu_temp_warm < mu_rain_yes) ? mu_temp_warm : mu_rain_yes);
                    4: rule[i] <= (mu_soil_dry < mu_temp_hot) ? ((mu_soil_dry < mu_rain_no) ? mu_soil_dry : mu_rain_no) : ((mu_temp_hot < mu_rain_no) ? mu_temp_hot : mu_rain_no);
                    5: rule[i] <= (mu_soil_dry < mu_temp_hot) ? ((mu_soil_dry < mu_rain_yes) ? mu_soil_dry : mu_rain_yes) : ((mu_temp_hot < mu_rain_yes) ? mu_temp_hot : mu_rain_yes);
                    6: rule[i] <= (mu_soil_moist < mu_temp_cold) ? ((mu_soil_moist < mu_rain_no) ? mu_soil_moist : mu_rain_no) : ((mu_temp_cold < mu_rain_no) ? mu_temp_cold : mu_rain_no);
                    7: rule[i] <= (mu_soil_moist < mu_temp_cold) ? ((mu_soil_moist < mu_rain_yes) ? mu_soil_moist : mu_rain_yes) : ((mu_temp_cold < mu_rain_yes) ? mu_temp_cold : mu_rain_yes);
                    8: rule[i] <= (mu_soil_moist < mu_temp_warm) ? ((mu_soil_moist < mu_rain_no) ? mu_soil_moist : mu_rain_no) : ((mu_temp_warm < mu_rain_no) ? mu_temp_warm : mu_rain_no);
                    9: rule[i] <= (mu_soil_moist < mu_temp_warm) ? ((mu_soil_moist < mu_rain_yes) ? mu_soil_moist : mu_rain_yes) : ((mu_temp_warm < mu_rain_yes) ? mu_temp_warm : mu_rain_yes);
                    10: rule[i] <= (mu_soil_moist < mu_temp_hot) ? ((mu_soil_moist < mu_rain_no) ? mu_soil_moist : mu_rain_no) : ((mu_temp_hot < mu_rain_no) ? mu_temp_hot : mu_rain_no);
                    11: rule[i] <= (mu_soil_moist < mu_temp_hot) ? ((mu_soil_moist < mu_rain_yes) ? mu_soil_moist : mu_rain_yes) : ((mu_temp_hot < mu_rain_yes) ? mu_temp_hot : mu_rain_yes);
                    12: rule[i] <= (mu_soil_wet < mu_temp_cold) ? ((mu_soil_wet < mu_rain_no) ? mu_soil_wet : mu_rain_no) : ((mu_temp_cold < mu_rain_no) ? mu_temp_cold : mu_rain_no);
                    13: rule[i] <= (mu_soil_wet < mu_temp_cold) ? ((mu_soil_wet < mu_rain_yes) ? mu_soil_wet : mu_rain_yes) : ((mu_temp_cold < mu_rain_yes) ? mu_temp_cold : mu_rain_yes);
                    14: rule[i] <= (mu_soil_wet < mu_temp_warm) ? ((mu_soil_wet < mu_rain_no) ? mu_soil_wet : mu_rain_no) : ((mu_temp_warm < mu_rain_no) ? mu_temp_warm : mu_rain_no);
                    15: rule[i] <= (mu_soil_wet < mu_temp_warm) ? ((mu_soil_wet < mu_rain_yes) ? mu_soil_wet : mu_rain_yes) : ((mu_temp_warm < mu_rain_yes) ? mu_temp_warm : mu_rain_yes);
                    16: rule[i] <= (mu_soil_wet < mu_temp_hot) ? ((mu_soil_wet < mu_rain_no) ? mu_soil_wet : mu_rain_no) : ((mu_temp_hot < mu_rain_no) ? mu_temp_hot : mu_rain_no);
                    17: rule[i] <= (mu_soil_wet < mu_temp_hot) ? ((mu_soil_wet < mu_rain_yes) ? mu_soil_wet : mu_rain_yes) : ((mu_temp_hot < mu_rain_yes) ? mu_temp_hot : mu_rain_yes);
                endcase

                numerator <= numerator + (rule[i] * irrigation_values[i]);
                denominator <= denominator + rule[i];
            end

            if (denominator > 0)
                irrigation_time <= numerator / denominator;
            else
                irrigation_time <= 0;

            if (rain_digital >= PARAM_RAIN_YES)
                rain_present <= 1'b1;
            else
                rain_present <= 1'b0;
        end
    end
endmodule
