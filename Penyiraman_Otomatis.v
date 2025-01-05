module SOIL_ADC #(parameter RESOLUTION = 10, VREF_MV = 5000)(
    input clk,
    input reset,
    input [15:0] analog_voltage_mv,
    input sensor_enable,  // New input to control ADC enable/disable
    output reg [RESOLUTION-1:0] digital_output
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digital_output <= 0;
        end else if (sensor_enable) begin
            // Perform ADC conversion when enabled
            digital_output <= (analog_voltage_mv * (2**RESOLUTION - 1)) / VREF_MV;
        end
    end

endmodule

module DHT11_ADC #(parameter RESOLUTION = 10, VREF_MV = 5000)(
    input clk,
    input reset,
    input [15:0] analog_voltage_mv,
	 input sensor_enable,
    output reg [RESOLUTION-1:0] digital_output
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digital_output <= 0;
        end else if (sensor_enable) begin
            digital_output <= (analog_voltage_mv * ((1 << RESOLUTION) - 1)) / VREF_MV;
        end
    end
endmodule

module RAIN_ADC #(parameter RESOLUTION = 10, VREF_MV = 5000)(
    input clk,
    input reset,
    input [15:0] analog_voltage_mv,
	 input sensor_enable,
    output reg [RESOLUTION-1:0] digital_output
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digital_output <= 0;
        end else if (sensor_enable) begin
            digital_output <= (analog_voltage_mv * ((1 << RESOLUTION) - 1)) / VREF_MV;
        end
    end
endmodule

module ADC_SENSOR #(parameter RESOLUTION = 10, VREF_MV = 5000)(
    input clk,
    input reset,
    input [15:0] soil_voltage_mv,     // Input dalam millivolt
    input [15:0] dht11_voltage_mv,
    input [15:0] rain_voltage_mv,
    input sensor_enable,              // New signal to enable/disable sensor readings
    output [RESOLUTION-1:0] soil_digital,
    output [RESOLUTION-1:0] dht11_digital,
    output [RESOLUTION-1:0] rain_digital
);

    // Instansiasi submodul untuk setiap sensor dengan kondisi sensor_enable
    SOIL_ADC #(RESOLUTION, VREF_MV) soil_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(soil_voltage_mv),
        .digital_output(soil_digital),
        .sensor_enable(sensor_enable)    // Enable/disable based on sensor_enable
    );

    DHT11_ADC #(RESOLUTION, VREF_MV) dht11_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(dht11_voltage_mv),
        .digital_output(dht11_digital),
        .sensor_enable(sensor_enable)    // Enable/disable based on sensor_enable
    );

    RAIN_ADC #(RESOLUTION, VREF_MV) rain_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(rain_voltage_mv),
        .digital_output(rain_digital),
        .sensor_enable(sensor_enable)    // Enable/disable based on sensor_enable
    );

endmodule

module FUZZIFIKASI #(
    parameter DATA_WIDTH = 10,        // Data width for ADC
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
    input [DATA_WIDTH-1:0] temp_digital,        // Digital temperature data
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

    // Initialize thresholds with default values
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

    // Threshold update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset thresholds to default values
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
        if (temp_digital <= PARAM_TEMP_COLD) begin
            mu_temp_cold = 1023; mu_temp_warm = 0; mu_temp_hot = 0;
        end else if (temp_digital <= PARAM_TEMP_WARM) begin
            mu_temp_cold = ((PARAM_TEMP_WARM - temp_digital) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
            mu_temp_warm = ((temp_digital - PARAM_TEMP_COLD) * 1023) / (PARAM_TEMP_WARM - PARAM_TEMP_COLD);
            mu_temp_hot = 0;
        end else if (temp_digital <= PARAM_TEMP_HOT) begin
            mu_temp_cold = 0;
            mu_temp_warm = ((PARAM_TEMP_HOT - temp_digital) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
            mu_temp_hot = ((temp_digital - PARAM_TEMP_WARM) * 1023) / (PARAM_TEMP_HOT - PARAM_TEMP_WARM);
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
    // Initialize irrigation values based on the rules directly
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
	 

    // Calculate numerator and denominator directly using irrigation values
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

        // Ensure the rules are correctly applied
        numerator = numerator + (rule[i] * irrigation_values[i]);
        denominator = denominator + rule[i];
    end

    // Display numerator and denominator for debugging
    //$display("Numerator: %d, Denominator: %d", numerator, denominator);

    // Calculate irrigation time
    if (denominator > 0)
        irrigation_time = numerator / denominator;
    else
        irrigation_time = 0;
	 
	 if (rain_digital >= PARAM_RAIN_YES) 
			rain_present = 1'b1; 
	 else 
			rain_present = 1'b0;

    //$display("Irrigation Time: %d", irrigation_time);
	end

endmodule

module Penyiraman_Otomatis (
    input clk,
    input reset,
    input [7:0] irrigation_time,   // Irrigation time in seconds
    output reg pump_on,             // Relay control for the pump
    output reg sensor_enable,       // Control for enabling/disabling sensor readings
    output reg watering_in_progress, // Indicator for watering status
    output reg [7:0] watering_timer // Countdown timer for watering
);

    reg [7:0] timer_count;  // Timer counter to track the irrigation time
    reg irrigation_active;  // Flag to indicate if irrigation is active
	 
    // Logic for controlling the pump based on irrigation time
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pump_on <= 0;
            sensor_enable <= 1;   // Enable sensor readings by default
            watering_in_progress <= 0;
            watering_timer <= 0;
            timer_count <= 0;
            irrigation_active <= 0;
        end else begin
            if (irrigation_active) begin
                // Count down the irrigation time
                if (timer_count > 0) begin
                    timer_count <= timer_count - 1;
                    watering_timer <= timer_count; // Update the countdown timer
						  sensor_enable <= 0;
                end else begin
                    // Time is up, turn off the pump and re-enable sensors
                    pump_on <= 0;
                    sensor_enable <= 1;
                    watering_in_progress <= 0; // Stop watering
                    irrigation_active <= 0;
                    watering_timer <= 0;  // Reset the timer
                end
            end else begin
                // Pump is off, wait for irrigation time to start
                if (irrigation_time > 0) begin
                    pump_on <= 1;  // Turn on the pump
                    sensor_enable <= 0;  // Disable sensor readings
                    watering_in_progress <= 1;  // Indicate watering is in progress
                    irrigation_active <= 1;  // Start irrigation process
                    timer_count <= irrigation_time;  // Set the timer for the irrigation time
                    watering_timer <= irrigation_time; // Start countdown
                end
            end
        end
    end

endmodule

module KEYPAD4x4 (
    input clk,
    input reset,
    input [3:0] row,          // Rows from the keypad
    input [3:0] col,          // Columns to the keypad
    output reg [3:0] category, // Selected category (1-8)
    output reg [9:0] new_value, // New value (0-1023)
    input start,              // Start button (A)
    input accept,             // Accept button (D)
    input backspace,          // Backspace button (B)
	 input [9:0] PARAM_SOIL_DRY,
    input [9:0] PARAM_SOIL_MOIST,
    input [9:0] PARAM_SOIL_WET,
    input [9:0] PARAM_TEMP_COLD,
    input [9:0] PARAM_TEMP_WARM,
    input [9:0] PARAM_TEMP_HOT,
    input [9:0] PARAM_RAIN_NO,
    input [9:0] PARAM_RAIN_YES,
    output reg updated,       // Indicates thresholds are updated
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

    // Internal signals
    reg [3:0] key_map;
    reg [3:0] current_state, next_state;
    reg [9:0] input_buffer;
    reg [15:0] rotation_counter;

    // State encoding
    localparam IDLE = 4'b0000,
               INPUT_CATEGORY = 4'b0001,
               INPUT_VALUE = 4'b0010,
               APPLY_CHANGE = 4'b0011;

    // Initialize
    initial begin
        updated = 1'b0;        // No updates initially
        update_soil_dry = 1'b0;
        update_soil_moist = 1'b0;
        update_soil_wet = 1'b0;
        update_temp_cold = 1'b0;
        update_temp_warm = 1'b0;
        update_temp_hot = 1'b0;
        update_rain_no = 1'b0;
        update_rain_yes = 1'b0;
    end

    // Map keypad rows and columns to key values
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_map <= 4'b0;
        end else begin
            case ({row, col})
                8'b1110_1110: key_map <= 4'h1; // Key '1'
                8'b1110_1101: key_map <= 4'h2; // Key '2'
                8'b1110_1011: key_map <= 4'h3; // Key '3'
                8'b1110_0111: key_map <= 4'hA; // Key 'A' (Start)
                8'b1101_1110: key_map <= 4'h4; // Key '4'
                8'b1101_1101: key_map <= 4'h5; // Key '5'
                8'b1101_1011: key_map <= 4'h6; // Key '6'
                8'b1101_0111: key_map <= 4'hB; // Key 'B' (Backspace)
                8'b1011_1110: key_map <= 4'h7; // Key '7'
                8'b1011_1101: key_map <= 4'h8; // Key '8'
                8'b1011_1011: key_map <= 4'h9; // Key '9'
                8'b1011_0111: key_map <= 4'hC; // Key 'C' (Reserved)
                8'b0111_1110: key_map <= 4'h0; // Key '0'
                8'b0111_1101: key_map <= 4'hF; // Key 'D' (Accept)
                default: key_map <= 4'b0;     // No key pressed
            endcase
        end
    end

    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            category <= 4'd0;
            new_value <= 10'd0;
            input_buffer <= 10'd0;
            updated <= 1'b0;
            update_soil_dry <= 1'b0;
            update_soil_moist <= 1'b0;
            update_soil_wet <= 1'b0;
            update_temp_cold <= 1'b0;
            update_temp_warm <= 1'b0;
            update_temp_hot <= 1'b0;
            update_rain_no <= 1'b0;
            update_rain_yes <= 1'b0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        updated = 1'b0; // Default
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = INPUT_CATEGORY;
                end
            end
            INPUT_CATEGORY: begin
                if (key_map > 4'h0 && key_map <= 4'h8) begin
                    category = key_map[3:0];
                    next_state = INPUT_VALUE;
                end
            end
            INPUT_VALUE: begin
                if (key_map == 4'hB) begin // Backspace
                    input_buffer = input_buffer / 10;
                end else if (key_map < 4'hA) begin // Valid input
                    input_buffer = (input_buffer * 10) + key_map;
                end
                if (accept) begin
                    new_value = input_buffer;
                    next_state = APPLY_CHANGE;
                end
            end
            APPLY_CHANGE: begin
                case (category)
                    4'd1: begin // Soil dry
							  if (new_value > 0 && new_value < PARAM_SOIL_MOIST) begin
									force NEW_PARAM_SOIL_DRY = new_value;
									NEW_PARAM_SOIL_DRY = new_value;
									update_soil_dry = 1'b0;
									#10;
									release NEW_PARAM_SOIL_DRY;
									updated = 1'b1;
							  end
						 end
						 4'd2: begin // Soil moist
							  if (new_value > PARAM_SOIL_DRY && new_value < PARAM_SOIL_DRY) begin
									if (new_value > PARAM_SOIL_WET) begin
										 // Ignore invalid value
									end else begin
										 force NEW_PARAM_SOIL_MOIST = new_value;
										 NEW_PARAM_SOIL_MOIST = new_value;
										 update_soil_moist <= 1'b1;
										 #10;
										 release NEW_PARAM_SOIL_MOIST;
										 updated = 1'b1;
									end
							  end
						 end
						 4'd3: begin // Soil wet
							  if (new_value > 0 && new_value > PARAM_SOIL_MOIST) begin
									force NEW_PARAM_SOIL_WET = new_value;
									NEW_PARAM_SOIL_WET = new_value;
									update_soil_wet <= 1'b1;
									#10;
									release NEW_PARAM_SOIL_WET;
									updated = 1'b1;
							  end
						 end
						 4'd4: begin // Temp cold
							  if (new_value > 0 && new_value < PARAM_TEMP_WARM) begin
									force NEW_PARAM_TEMP_COLD = new_value;
									NEW_PARAM_TEMP_COLD = new_value;
									update_temp_cold <= 1'b1;
									#10;
									release NEW_PARAM_TEMP_COLD;
									updated = 1'b1;
							  end
						 end
						 4'd5: begin // Temp warm
							  if (new_value > PARAM_TEMP_COLD && new_value < PARAM_TEMP_HOT) begin
									if (new_value > PARAM_TEMP_HOT) begin
										 // Ignore invalid value
									end else begin
										 force NEW_PARAM_TEMP_WARM = new_value;
										 NEW_PARAM_TEMP_WARM = new_value;
										 update_temp_warm <= 1'b1;
										 #10;
										 release NEW_PARAM_TEMP_WARM;
										 updated = 1'b1;
									end
							  end
						 end
						 4'd6: begin // Temp hot
							  if (new_value > 0 && new_value > PARAM_TEMP_WARM) begin
									force NEW_PARAM_TEMP_HOT = new_value;
									NEW_PARAM_TEMP_HOT = new_value;
									update_temp_hot <= 1'b1;
									#10;
									release NEW_PARAM_TEMP_HOT;
									updated = 1'b1;
							  end
						 end
						 4'd7: begin // Rain no
							  if (new_value > 0 && new_value < PARAM_RAIN_YES) begin
									force NEW_PARAM_RAIN_NO = new_value;
									NEW_PARAM_RAIN_NO = new_value;
									update_rain_no <= 1'b1;
									#10;
									release NEW_PARAM_RAIN_NO;
									updated = 1'b1;
							  end
						 end
						 4'd8: begin // Rain yes
							  if (new_value >= 0 && new_value > PARAM_RAIN_NO) begin
									force NEW_PARAM_RAIN_YES = new_value;
									NEW_PARAM_RAIN_YES = new_value;
									update_rain_yes <= 1'b1;
									#10;
									release NEW_PARAM_RAIN_YES;
									updated = 1'b1;
							  end
						 end
                endcase

                next_state = IDLE;
            end
        endcase
    end

    // Column rotation for keypad scanning
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rotation_counter <= 16'd0;
        end else begin
            if (rotation_counter == 16'd50000) begin // Adjust timing as needed
                rotation_counter <= 16'd0;
            end else begin
                rotation_counter <= rotation_counter + 1;
            end
        end
    end
endmodule

module LCD_I2C (
    input clk,
    input reset,
    input [9:0] dht11_digital,  // Temperature sensor data
    input [9:0] soil_digital,   // Soil sensor data
    input [9:0] rain_digital,   // Rain sensor data
    input watering_in_progress,
    input [7:0] watering_timer,
    input sensor_enable,
    output reg [23:0] lcd_data, // LCD data (TEMP: 8 bits, SOIL: 8 bits, RAIN: 8 bits)
    output reg [23:0] lcd_message_data,
    output reg sda,              // I2C data line
    output reg scl               // I2C clock line
);

    reg [7:0] temp_scaled;
    reg [7:0] soil_scaled;
    reg [7:0] rain_scaled;
    reg [1:0] message_state;     // State variable to track which message is being displayed
    reg [15:0] message_timer;    // Timer for switching messages

    parameter MESSAGE_CYCLE_TIME = 1000; // Number of clock cycles per message

    // Scale sensor values
    always @(*) begin
        soil_scaled = (soil_digital * 255) / 1023;
        temp_scaled = (dht11_digital * 255) / 1023;
        rain_scaled = (rain_digital * 255) / 1023;
        lcd_data = {soil_scaled, temp_scaled, rain_scaled};
    end

    // Initialize message states
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        message_state <= 0;
        message_timer <= 0;
        lcd_message_data <= 24'h4e554c; // Default "NUL"
    end else begin
        if (watering_in_progress) begin
            // Cycle through messages while watering
            if (message_timer >= MESSAGE_CYCLE_TIME) begin
                message_timer <= 0;
                message_state <= (message_state + 1) % 2; // Cycle through "WAT" and "DON"
					 if (watering_in_progress == 0) begin
						  lcd_message_data <= 24'h444f4e;
					 end
            end else begin
                message_timer <= message_timer + 1;
            end

            // Assign messages based on state
            case (message_state)
                0: lcd_message_data <= 24'h574154; // "WAT"
                1: lcd_message_data <= 24'h444f4e; // "DON"
            endcase
        end else begin
            // Default to "IDL" when not watering
            message_state <= 0;
            message_timer <= 0;
            lcd_message_data <= 24'h49444c; // "IDL"
        end
    end
end

    // Simulate SDA and SCL signals for I2C
    always @(posedge clk) begin
        sda <= lcd_message_data[0];
        scl <= ~sda;
    end
endmodule