module Penyiraman_Otomatis_tb;

    // Parameters
    parameter RESOLUTION = 10; // Set resolution to 10-bit for ADC values
    parameter VREF_MV = 5000;

    // Inputs and Outputs
    reg clk;
    reg reset;
    reg [15:0] soil_voltage_mv;
    reg [15:0] dht11_voltage_mv;
    reg [15:0] rain_voltage_mv;
	 reg enable;
    wire sensor_enable;

    wire [RESOLUTION-1:0] soil_digital;
    wire [RESOLUTION-1:0] dht11_digital;
    wire [RESOLUTION-1:0] rain_digital;
    wire [7:0] irrigation_time;
    wire rain_present;
    wire [23:0] lcd_data;  // Updated to 24 bits
    wire [127:0] lcd_message_data;
    wire sda, scl;

    // Control signals
    wire pump_on;  // Relay control for the pump
    wire watering_in_progress; // Indicator for watering status
    wire [7:0] watering_timer;  // Countdown timer for watering
	 
	 reg [3:0] row;
    reg [3:0] col;
    wire [3:0] category;
    wire [9:0] new_value;
    wire updated;
	 reg start, accept, backspace;
	 
	 reg [9:0] new_soil_dry;
    reg [9:0] new_soil_moist;
    reg [9:0] new_soil_wet;
    reg [9:0] new_temp_cold;
    reg [9:0] new_temp_warm;
    reg [9:0] new_temp_hot;
    reg [9:0] new_rain_no;
    reg [9:0] new_rain_yes;
	 wire [9:0] PARAM_SOIL_DRY;
    wire [9:0] PARAM_SOIL_MOIST;
    wire [9:0] PARAM_SOIL_WET;
    wire [9:0] PARAM_TEMP_COLD;
    wire [9:0] PARAM_TEMP_WARM;
    wire [9:0] PARAM_TEMP_HOT;
    wire [9:0] PARAM_RAIN_NO;
    wire [9:0] PARAM_RAIN_YES;
	 
	 wire [9:0] NEW_PARAM_SOIL_DRY;
    wire [9:0] NEW_PARAM_SOIL_MOIST;
    wire [9:0] NEW_PARAM_SOIL_WET;
    wire [9:0] NEW_PARAM_TEMP_COLD;
    wire [9:0] NEW_PARAM_TEMP_WARM;
    wire [9:0] NEW_PARAM_TEMP_HOT;
    wire [9:0] NEW_PARAM_RAIN_NO;
    wire [9:0] NEW_PARAM_RAIN_YES;
	 
    wire update_soil_dry;
    wire update_soil_moist;
    wire update_soil_wet;
    wire update_temp_cold;
    wire update_temp_warm;
    wire update_temp_hot;
    wire update_rain_no;
    wire update_rain_yes;

    // Instantiate the ADC_SENSOR module
    ADC_SENSOR #(RESOLUTION, VREF_MV) uut_adc (
        .clk(clk),
        .reset(reset),
        .soil_voltage_mv(soil_voltage_mv),
        .dht11_voltage_mv(dht11_voltage_mv),
        .rain_voltage_mv(rain_voltage_mv),
        .sensor_enable(sensor_enable),  // Pass the sensor_enable signal
        .soil_digital(soil_digital),
        .dht11_digital(dht11_digital),
        .rain_digital(rain_digital)
    );

    // Instantiate the FUZZIFIKASI module
    FUZZIFIKASI uut_fuzzy (
        .clk(clk),
        .reset(reset),
        .new_soil_dry(NEW_PARAM_SOIL_DRY),
        .new_soil_moist(NEW_PARAM_SOIL_MOIST),
        .new_soil_wet(NEW_PARAM_SOIL_WET),
        .new_temp_cold(NEW_PARAM_TEMP_COLD),
        .new_temp_warm(NEW_PARAM_TEMP_WARM),
        .new_temp_hot(NEW_PARAM_TEMP_HOT),
        .new_rain_no(NEW_PARAM_RAIN_NO),
        .new_rain_yes(NEW_PARAM_RAIN_YES),
        .update_soil_dry(update_soil_dry),
        .update_soil_moist(update_soil_moist),
        .update_soil_wet(update_soil_wet),
        .update_temp_cold(update_temp_cold),
        .update_temp_warm(update_temp_warm),
        .update_temp_hot(update_temp_hot),
        .update_rain_no(update_rain_no),
        .update_rain_yes(update_rain_yes),
        .soil_digital(soil_digital),
        .temp_digital(temp_digital),
        .rain_digital(rain_digital),
        .irrigation_time(irrigation_time),
        .rain_present(rain_present),
        .PARAM_SOIL_DRY(PARAM_SOIL_DRY),
        .PARAM_SOIL_MOIST(PARAM_SOIL_MOIST),
        .PARAM_SOIL_WET(PARAM_SOIL_WET),
        .PARAM_TEMP_COLD(PARAM_TEMP_COLD),
        .PARAM_TEMP_WARM(PARAM_TEMP_WARM),
        .PARAM_TEMP_HOT(PARAM_TEMP_HOT),
        .PARAM_RAIN_NO(PARAM_RAIN_NO),
        .PARAM_RAIN_YES(PARAM_RAIN_YES)
    );

    // Instantiate the PUMP CONTROL module
    Penyiraman_Otomatis uut_pump (
        .clk(clk),
        .reset(reset),
        .irrigation_time(irrigation_time),
        .pump_on(pump_on),
        .sensor_enable(sensor_enable),
        .watering_in_progress(watering_in_progress),
        .watering_timer(watering_timer)
    );

    // Instantiate the LCD module
    LCD_I2C uut_lcd (
        .clk(clk),
        .reset(reset),
        .dht11_digital(dht11_digital),    // Connect the temperature sensor
        .soil_digital(soil_digital),      // Connect the soil sensor
        .rain_digital(rain_digital),      // Connect the rain sensor
        .watering_in_progress(watering_in_progress),  // Connect the watering_in_progress signal
        .lcd_data(lcd_data),              // The LCD data will hold the combined sensor data
        .lcd_message_data(lcd_message_data),
        .sda(sda),                        // I2C data line
        .scl(scl)                         // I2C clock line
    );

    KEYPAD4x4 uut_keypad (
        .clk(clk),
        .reset(reset),
        .row(row),
        .col(col),
        .category(category),
        .new_value(new_value),
        .start(start),
        .accept(accept),
        .backspace(backspace),
		  .PARAM_SOIL_DRY(PARAM_SOIL_DRY),
        .PARAM_SOIL_MOIST(PARAM_SOIL_MOIST),
        .PARAM_SOIL_WET(PARAM_SOIL_WET),
        .PARAM_TEMP_COLD(PARAM_TEMP_COLD),
        .PARAM_TEMP_WARM(PARAM_TEMP_WARM),
        .PARAM_TEMP_HOT(PARAM_TEMP_HOT),
        .PARAM_RAIN_NO(PARAM_RAIN_NO),
        .PARAM_RAIN_YES(PARAM_RAIN_YES),
        .updated(updated),
		  .NEW_PARAM_SOIL_DRY(NEW_PARAM_SOIL_DRY),
        .NEW_PARAM_SOIL_MOIST(NEW_PARAM_SOIL_MOIST),
        .NEW_PARAM_SOIL_WET(NEW_PARAM_SOIL_WET),
        .NEW_PARAM_TEMP_COLD(NEW_PARAM_TEMP_COLD),
        .NEW_PARAM_TEMP_WARM(NEW_PARAM_TEMP_WARM),
        .NEW_PARAM_TEMP_HOT(NEW_PARAM_TEMP_HOT),
        .NEW_PARAM_RAIN_NO(NEW_PARAM_RAIN_NO),
        .NEW_PARAM_RAIN_YES(NEW_PARAM_RAIN_YES),
        .update_soil_dry(update_soil_dry),
        .update_soil_moist(update_soil_moist),
        .update_soil_wet(update_soil_wet),
        .update_temp_cold(update_temp_cold),
        .update_temp_warm(update_temp_warm),
        .update_temp_hot(update_temp_hot),
        .update_rain_no(update_rain_no),
        .update_rain_yes(update_rain_yes)
    );


    // Clock generation
    always #10 clk = ~clk; // 10ns period clock
	 integer i;

    // Test sequence
initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    soil_voltage_mv = 0;
    dht11_voltage_mv = 0;
    rain_voltage_mv = 0;
    enable = 1;  // Initialize as enabled

    start = 0;
    accept = 0;
    backspace = 0;
    row = 4'b1111;

    #10;
    reset = 0;

    fork
        // Generate random test values in a loop
        forever begin
            // Simulate sensor readings when enabled
            if (enable) begin
                soil_voltage_mv = $random % 5000; // Random value between 0 and 5000
                dht11_voltage_mv = $random % 5000; // Random value between 0 and 5000
                rain_voltage_mv = $random % 5000; // Random value between 0 and 5000
            end
            #10; // Delay for the next iteration
        end

        // Interrupt for threshold update every 500 time units
        forever begin
            #500; // Wait 500 time units
            $display("Interrupting to update thresholds...");

            // Randomly select start
            #10 start = 1;
            #10 start = 0;

            // Generate random row value for categories (1-8)
            case ($random % 8)
					 0: begin 
						  row = 4'b1110; 
						  col = 4'b1110; // Key '1'
					 end
					 1: begin 
						  row = 4'b1110; 
						  col = 4'b1101; // Key '2'
					 end
					 2: begin 
						  row = 4'b1110; 
						  col = 4'b1011; // Key '3'
					 end
					 3: begin 
						  row = 4'b1101; 
						  col = 4'b1110; // Key '4'
					 end
					 4: begin 
						  row = 4'b1101; 
						  col = 4'b1101; // Key '5'
					 end
					 5: begin 
						  row = 4'b1101; 
						  col = 4'b1011; // Key '6'
					 end
					 6: begin 
						  row = 4'b1011; 
						  col = 4'b1110; // Key '7'
					 end
					 7: begin 
						  row = 4'b1011; 
						  col = 4'b1101; // Key '8'
					 end
				endcase

            #20 row = 4'b1111; // Release key

            // Enter a random value for the parameter (0-9 for each digit)
            for (i = 0; i < 3; i = i + 1) begin
                case ($random % 8)
						 0: begin 
							  row = 4'b1110; 
							  col = 4'b1110; // Key '1'
						 end
						 1: begin 
							  row = 4'b1110; 
							  col = 4'b1101; // Key '2'
						 end
						 2: begin 
							  row = 4'b1110; 
							  col = 4'b1011; // Key '3'
						 end
						 3: begin 
							  row = 4'b1101; 
							  col = 4'b1110; // Key '4'
						 end
						 4: begin 
							  row = 4'b1101; 
							  col = 4'b1101; // Key '5'
						 end
						 5: begin 
							  row = 4'b1101; 
							  col = 4'b1011; // Key '6'
						 end
						 6: begin 
							  row = 4'b1011; 
							  col = 4'b1110; // Key '7'
						 end
						 7: begin 
							  row = 4'b1011; 
							  col = 4'b1101; // Key '8'
						 end
					endcase

                #20 row = 4'b1111; // Release key
            end

            // Accept the input
            #10 accept = 1;
            #10 accept = 0;
            #10;

            $display("Updated thresholds -> Category: %d, New Value: %d, Updated: %b", category, new_value, updated);

				$display("Updated thresholds -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
            PARAM_SOIL_DRY, PARAM_SOIL_MOIST, PARAM_SOIL_WET, PARAM_TEMP_COLD, PARAM_TEMP_WARM, PARAM_TEMP_HOT, PARAM_RAIN_NO, PARAM_RAIN_YES);    
 

            $display("Resuming sensor readings...\n");
				#10;
        end
    join
end

// Monitor outputs
initial begin
    $monitor($time, 
        " Soil Digital: %d, Temp Digital: %d, Rain Digital: %d, Rain Present: %b, Irrigation Time: %d s, Pump On: %b, Sensor Enable: %b, Watering In Progress: %b, Countdown Timer: %d s, LCD Data (SOIL: %d, TEMP: %d, RAIN: %d, Message: %s)\n",
        soil_digital, dht11_digital, rain_digital, 
        rain_present, irrigation_time, pump_on, sensor_enable, watering_in_progress, watering_timer,
        uut_lcd.soil_scaled, uut_lcd.temp_scaled, uut_lcd.rain_scaled, uut_lcd.lcd_message_data);  // Extract each 8-bit segment
end


endmodule
