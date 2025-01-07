module FUZZIFIKASI #(
    parameter DATA_WIDTH = 10,
    parameter DEFAULT_SOIL_DRY = 10'd400,   // Dry soil threshold (default)
    parameter DEFAULT_SOIL_MOIST = 10'd600, // Moist soil threshold (default)
    parameter DEFAULT_SOIL_WET = 10'd800,   // Wet soil threshold (default)
    parameter DEFAULT_TEMP_COLD = 10'd300,  // Cold temperature threshold (default)
    parameter DEFAULT_TEMP_WARM = 10'd500,  // Warm temperature threshold (default)
    parameter DEFAULT_TEMP_HOT = 10'd700,   // Hot temperature threshold (default)
    parameter DEFAULT_RAIN_NO = 10'd100,    // Low rain threshold (default)
    parameter DEFAULT_RAIN_YES = 10'd400    // High rain threshold (default)
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
    input [DATA_WIDTH-1:0] soil_digital,        // Digital soil moisture data
    input [DATA_WIDTH-1:0] dht11_digital,        // Digital temperature data
    input [DATA_WIDTH-1:0] rain_digital,        // Digital rain data
    output reg [7:0] irrigation_time,           // Irrigation time in seconds
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

    initial begin
        PARAM_SOIL_DRY = DEFAULT_SOIL_DRY;
        PARAM_SOIL_MOIST = DEFAULT_SOIL_MOIST;
        PARAM_SOIL_WET = DEFAULT_SOIL_WET;
        PARAM_TEMP_COLD = DEFAULT_TEMP_COLD;
        PARAM_TEMP_WARM = DEFAULT_TEMP_WARM;
        PARAM_TEMP_HOT = DEFAULT_TEMP_HOT;
        PARAM_RAIN_NO = DEFAULT_RAIN_NO;
        PARAM_RAIN_YES = DEFAULT_RAIN_YES;
    end

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
        end else begin
            if (update_soil_dry) begin
                PARAM_SOIL_DRY <= new_soil_dry;
            end
            if (update_soil_moist) begin
                PARAM_SOIL_MOIST <= new_soil_moist;
            end
            if (update_soil_wet) begin
                PARAM_SOIL_WET <= new_soil_wet;
            end
            if (update_temp_cold) begin
                PARAM_TEMP_COLD <= new_temp_cold;
            end
            if (update_temp_warm) begin
                PARAM_TEMP_WARM <= new_temp_warm;
            end
            if (update_temp_hot) begin
                PARAM_TEMP_HOT <= new_temp_hot;
            end
            if (update_rain_no) begin
                PARAM_RAIN_NO <= new_rain_no;
            end
            if (update_rain_yes) begin
                PARAM_RAIN_YES <= new_rain_yes;
            end
        end
    end
	 	 

    function [DATA_WIDTH-1:0] min_two;
        input [DATA_WIDTH-1:0] a, b;
        begin
            min_two = (a < b) ? a : b;
        end
    endfunction

    // Function to compute the minimum of three values
    function [DATA_WIDTH-1:0] min_three;
        input [DATA_WIDTH-1:0] a, b, c;
        begin
            min_three = min_two(min_two(a, b), c);
        end
    endfunction

    // Fuzzy memberships
    reg [DATA_WIDTH-1:0] mu_soil_dry, mu_soil_moist, mu_soil_wet;
    reg [DATA_WIDTH-1:0] mu_temp_cold, mu_temp_warm, mu_temp_hot;
    reg [DATA_WIDTH-1:0] mu_rain_no, mu_rain_yes;
    
    // Declare variables for max rule
    integer max_rule_index;
    reg [DATA_WIDTH-1:0] max_rule_value;

    // Fuzzification
    always @(*) begin
        // Soil moisture membership
        if (soil_digital <= PARAM_SOIL_DRY) begin
            mu_soil_dry = 1023; mu_soil_moist = 0; mu_soil_wet = 0;
        end else if (soil_digital <= PARAM_SOIL_MOIST) begin
            mu_soil_dry = ((PARAM_SOIL_MOIST - soil_digital) * 1023) / (PARAM_SOIL_MOIST - PARAM_SOIL_DRY);
            mu_soil_moist = ((soil_digital - PARAM_SOIL_DRY) * 1023) / (PARAM_SOIL_MOIST - PARAM_SOIL_DRY);
            mu_soil_wet = 0;
        end else if (soil_digital <= PARAM_SOIL_WET) begin
            mu_soil_dry = 0;
            mu_soil_moist = ((PARAM_SOIL_WET - soil_digital) * 1023) / (PARAM_SOIL_WET - PARAM_SOIL_MOIST);
            mu_soil_wet = ((soil_digital - PARAM_SOIL_MOIST) * 1023) / (PARAM_SOIL_WET - PARAM_SOIL_MOIST);
        end else begin
            mu_soil_dry = 0; mu_soil_moist = 0; mu_soil_wet = 1023;
        end

        // Temperature membership
        if (dht11_digital <= PARAM_TEMP_COLD) begin
            mu_temp_cold = 1023; mu_temp_warm = 0; mu_temp_hot = 0;
        end else if (dht11_digital <= PARAM_TEMP_WARM) begin
            mu_temp_cold = ((PARAM_TEMP_WARM - dht11_digital) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
            mu_temp_warm = ((dht11_digital - PARAM_TEMP_COLD) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
            mu_temp_hot = 0;
        end else if (dht11_digital <= PARAM_TEMP_HOT) begin
            mu_temp_cold = 0;
            mu_temp_warm = ((PARAM_TEMP_HOT - dht11_digital) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
            mu_temp_hot = ((dht11_digital - PARAM_TEMP_WARM) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
        end else begin
            mu_temp_cold = 0; mu_temp_warm = 0; mu_temp_hot = 1023;
        end

        // Rain membership
        if (rain_digital <= PARAM_RAIN_NO) begin
            mu_rain_no = 1023; mu_rain_yes = 0;
        end else if (rain_digital <= PARAM_RAIN_YES) begin
            mu_rain_no = ((PARAM_RAIN_YES - rain_digital) * 1023) / (PARAM_RAIN_YES - PARAM_RAIN_NO);
            mu_rain_yes = ((rain_digital - PARAM_RAIN_NO) * 1023) / (PARAM_RAIN_YES - PARAM_RAIN_NO);
        end else begin
            mu_rain_no = 0; mu_rain_yes = 1023;
        end
    end

    reg [DATA_WIDTH-1:0] rule[17:0];
    reg [7:0] nilai_penyiraman[3:0];
    reg [DATA_WIDTH+7:0] numerator, denominator;
    reg [DATA_WIDTH+7:0] weighted_value;
    integer i;
	 reg [7:0] irrigation_values[17:0];

    always @(*) begin
    irrigation_values[0] = 8'd0;  // Rule 0: No irrigation
    irrigation_values[1] = 8'd0;  // Rule 1: No irrigation
    irrigation_values[2] = 8'd10; // Rule 2: Light irrigation
    irrigation_values[3] = 8'd0; // Rule 3: Light irrigation
    irrigation_values[4] = 8'd45; // Rule 4: Moderate irrigation
    irrigation_values[5] = 8'd0; // Rule 5: High irrigation
    irrigation_values[6] = 8'd0;  // Rule 6: No irrigation
    irrigation_values[7] = 8'd0;  // Rule 7: No irrigation
    irrigation_values[8] = 8'd10; // Rule 8: Light irrigation
    irrigation_values[9] = 8'd0; // Rule 9: Light irrigation
    irrigation_values[10] = 8'd45; // Rule 10: Moderate irrigation
    irrigation_values[11] = 8'd0; // Rule 11: High irrigation
    irrigation_values[12] = 8'd0;  // Rule 12: No irrigation
    irrigation_values[13] = 8'd0;  // Rule 13: No irrigation
    irrigation_values[14] = 8'd10; // Rule 14: Light irrigation
    irrigation_values[15] = 8'd0; // Rule 15: Light irrigation
    irrigation_values[16] = 8'd30; // Rule 16: Moderate irrigation
    irrigation_values[17] = 8'd0; // Rule 17: Moderate irrigation

    numerator = 0;
    denominator = 0;
	 


    for (i = 0; i < 18; i = i + 1) begin
        rule[i] = 0;
        case (i)
            0: rule[i] = min_three(mu_soil_dry, mu_temp_cold, mu_rain_no);
            1: rule[i] = min_three(mu_soil_dry, mu_temp_cold, mu_rain_yes);
            2: rule[i] = min_three(mu_soil_dry, mu_temp_warm, mu_rain_no);
            3: rule[i] = min_three(mu_soil_dry, mu_temp_warm, mu_rain_yes);
            4: rule[i] = min_three(mu_soil_dry, mu_temp_hot, mu_rain_no);
            5: rule[i] = min_three(mu_soil_dry, mu_temp_hot, mu_rain_yes);
            6: rule[i] = min_three(mu_soil_moist, mu_temp_cold, mu_rain_no);
            7: rule[i] = min_three(mu_soil_moist, mu_temp_cold, mu_rain_yes);
            8: rule[i] = min_three(mu_soil_moist, mu_temp_warm, mu_rain_no);
            9: rule[i] = min_three(mu_soil_moist, mu_temp_warm, mu_rain_yes);
            10: rule[i] = min_three(mu_soil_moist, mu_temp_hot, mu_rain_no);
            11: rule[i] = min_three(mu_soil_moist, mu_temp_hot, mu_rain_yes);
            12: rule[i] = min_three(mu_soil_wet, mu_temp_cold, mu_rain_no);
            13: rule[i] = min_three(mu_soil_wet, mu_temp_cold, mu_rain_yes);
            14: rule[i] = min_three(mu_soil_wet, mu_temp_warm, mu_rain_no);
            15: rule[i] = min_three(mu_soil_wet, mu_temp_warm, mu_rain_yes);
            16: rule[i] = min_three(mu_soil_wet, mu_temp_hot, mu_rain_no);
            17: rule[i] = min_three(mu_soil_wet, mu_temp_hot, mu_rain_yes);
        endcase

        numerator = numerator + (rule[i] * irrigation_values[i]);
        denominator = denominator + rule[i];
    end
    if (denominator > 0)
        irrigation_time = numerator / denominator;
    else
        irrigation_time = 0;
	 
	 if (rain_digital >= PARAM_RAIN_YES) 
			rain_present = 1'b1; 
	 else 
			rain_present = 1'b0;

	end

endmodule