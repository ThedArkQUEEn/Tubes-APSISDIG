module Penyiraman_Otomatis_Keypad_tb;
    parameter VREF_MV = 5000;

    // Inputs
    reg clk;
    reg reset;
    reg [15:0] soil_voltage_mv;
    reg [15:0] dht11_voltage_mv;
    reg [15:0] rain_voltage_mv;
    reg [3:0] keypad_row;
    reg [3:0] keypad_col;
    wire keypad_start;
    wire keypad_accept;
    wire keypad_backspace;
    reg enable;

    // Outputs
    wire [3:0] category;
    wire [9:0] new_value;
    wire pump_on;
    wire rain_present;
    wire watering_in_progress;
    wire sensor_enable;
    wire sda;
    wire scl;
    wire [9:0] soil_digital;
    wire [9:0] dht11_digital;
    wire [9:0] rain_digital;
    wire [7:0] irrigation_time;
    wire update_soil_dry;
    wire update_soil_moist;
    wire update_soil_wet;
    wire update_temp_cold;
    wire update_temp_warm;
    wire update_temp_hot;
    wire update_rain_no;
    wire update_rain_yes;
    wire updated;
    wire [7:0] watering_timer;
    wire [9:0] param_soil_dry;
    wire [9:0] param_soil_moist;
    wire [9:0] param_soil_wet;
    wire [9:0] param_temp_cold;
    wire [9:0] param_temp_warm;
    wire [9:0] param_temp_hot;
    wire [9:0] param_rain_no;
    wire [9:0] param_rain_yes;
    wire [23:0] lcd_data;
    wire [23:0] lcd_message_data;
	 integer i, num;
	 wire [9:0] new_soil_dry;
    wire [9:0] new_soil_moist;
    wire [9:0] new_soil_wet;
    wire [9:0] new_temp_cold;
    wire [9:0] new_temp_warm;
    wire [9:0] new_temp_hot;
    wire [9:0] new_rain_no;
    wire [9:0] new_rain_yes;

    // Instantiate the Top Module
    Top_Module uut (
        .clk(clk),
        .reset(reset),
        .soil_voltage_mv(soil_voltage_mv),
        .dht11_voltage_mv(dht11_voltage_mv),
        .rain_voltage_mv(rain_voltage_mv),
        .keypad_row(keypad_row),
        .keypad_col(keypad_col),
        .keypad_start(keypad_start),
        .keypad_accept(keypad_accept),
        .keypad_backspace(keypad_backspace),
        .category(category),
        .new_value(new_value),
        .pump_on(pump_on),
        .rain_present(rain_present),
        .watering_in_progress(watering_in_progress),
        .sensor_enable(sensor_enable),
        .sda(sda),
        .scl(scl),
        .soil_digital(soil_digital),
        .dht11_digital(dht11_digital),
        .rain_digital(rain_digital),
        .irrigation_time(irrigation_time),
        .new_soil_dry(new_soil_dry),
        .new_soil_moist(new_soil_moist),
        .new_soil_wet(new_soil_wet),
        .new_temp_cold(new_temp_cold),
        .new_temp_warm(new_temp_warm),
        .new_temp_hot(new_temp_hot),
        .new_rain_no(new_rain_no),
        .new_rain_yes(new_rain_yes),
        .update_soil_dry(update_soil_dry),
        .update_soil_moist(update_soil_moist),
        .update_soil_wet(update_soil_wet),
        .update_temp_cold(update_temp_cold),
        .update_temp_warm(update_temp_warm),
        .update_temp_hot(update_temp_hot),
        .update_rain_no(update_rain_no),
        .update_rain_yes(update_rain_yes),
        .updated(updated),
        .watering_timer(watering_timer),
        .param_soil_dry(param_soil_dry),
        .param_soil_moist(param_soil_moist),
        .param_soil_wet(param_soil_wet),
        .param_temp_cold(param_temp_cold),
        .param_temp_warm(param_temp_warm),
        .param_temp_hot(param_temp_hot),
        .param_rain_no(param_rain_no),
        .param_rain_yes(param_rain_yes),
        .lcd_data(lcd_data),
        .lcd_message_data(lcd_message_data)
    );

	 always #10 clk = ~clk;

initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        soil_voltage_mv = 0;
        dht11_voltage_mv = 0;
        rain_voltage_mv = 0;
        enable = 1;

        // Reset the module
        #10;
        reset = 0;

        // First sensor reading
		  soil_voltage_mv = 1500;
		  dht11_voltage_mv = 3300;
		  rain_voltage_mv = 1000;
		  #10;  // Allow outputs to stabilize

		  $display($time,
		  " Soil Digital: %d, Temp Digital: %d, Rain Digital: %d, Rain Present: %b, Irrigation Time: %d s, Pump On: %b, Sensor Enable: %b, Watering In Progress: %b, Countdown Timer: %d s, LCD Data (SOIL: %d, TEMP: %d, RAIN: %d, Message: %s)\n",
		  soil_digital, dht11_digital, rain_digital, rain_present, irrigation_time, pump_on, sensor_enable, watering_in_progress, watering_timer,
		  lcd_data[23:16], lcd_data[15:8], lcd_data[7:0], lcd_message_data); // Extract each 8-bit segment
		  
		  #10;
		  keypad_row = 4'b1110; keypad_col = 4'b0111; #10;	// Start
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1110; keypad_col = 4'b1101; #10; // Select Category 2 (Soil Moist) 1110_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1110; #10; // Input value '7' 1011_1110
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1101; keypad_col = 4'b0111; #10; // Backspace		1101_0111
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1110; #10; // Input value '7' 1011_1110
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b0111; keypad_col = 4'b1101; #10; // Accept 			0111_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  #10;
		  #10; 
		  #10;
		  #10;
		  #10;
		  #10;
		  
		  $display("\nSimulating keypad input...");
		  $display("Updated thresholds -> Category: %d, New Value: %d, Updated: %b", category, new_value, updated);
		  $display("What get updated -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  new_soil_dry, new_soil_moist, new_soil_wet, new_temp_cold, new_temp_warm, new_temp_hot, new_rain_no, new_rain_yes);
		  $display("Updated thresholds -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  param_soil_dry, param_soil_moist, param_soil_wet, param_temp_cold, param_temp_warm, param_temp_hot, param_rain_no, param_rain_yes);
		  $display("Resuming sensor readings...\n");
		  
		  keypad_row = 4'b1110; keypad_col = 4'b0111; #10;	// Start
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1110; keypad_col = 4'b1011; #10; // Select Category 3 1110_1011
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1110; #10; // Input value '7' 1011_1110
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1101; #10; // Input value '8' 1011_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1011; #10; // Input value '9' 1011_1011
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b0111; keypad_col = 4'b1101; #10; // Accept 			0111_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  #10;
		  #10;
		  #10;
		  #10;
		  #10;
		  #10;
		  		  
		  $display("\nSimulating keypad input...");
		  $display("Updated thresholds -> Category: %d, New Value: %d, Updated: %b", category, new_value, updated);
		  $display("What get updated -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  new_soil_dry, new_soil_moist, new_soil_wet, new_temp_cold, new_temp_warm, new_temp_hot, new_rain_no, new_rain_yes);		  
		  $display("Updated thresholds -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  param_soil_dry, param_soil_moist, param_soil_wet, param_temp_cold, param_temp_warm, param_temp_hot, param_rain_no, param_rain_yes);
		  $display("Resuming sensor readings...\n");
		  
		  keypad_row = 4'b1110; keypad_col = 4'b0111; #10;	// Start
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1101; keypad_col = 4'b1011; #10; // Select Category 6 (Soil Moist) b1101_1011
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1110; #10; // Input value '7' 1011_1110
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1101; #10; // Input value '8' 1011_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b1011; keypad_col = 4'b1011; #10; // Input value '9' 1011_1011
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  keypad_row = 4'b0111; keypad_col = 4'b1101; #10; // Accept 			0111_1101
		  keypad_row = 4'b1111; keypad_col = 4'b1111; #10; // Release key
		  #10;		  
		  #10;
		  #10;
		  #10;		  
		  #10;
		  #10;
		  
		  $display("\nSimulating keypad input...");
		  $display("Updated thresholds -> Category: %d, New Value: %d, Updated: %b", category, new_value, updated);
		  $display("What get updated -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  new_soil_dry, new_soil_moist, new_soil_wet, new_temp_cold, new_temp_warm, new_temp_hot, new_rain_no, new_rain_yes);
		  $display("Updated thresholds -> Soil Dry: %d, Soil Moist: %d, Soil Wet: %d, Temp Cold: %d, Temp Warm: %d, Temp Hot: %d, Rain No: %d, Rain Yes: %d", 
		  param_soil_dry, param_soil_moist, param_soil_wet, param_temp_cold, param_temp_warm, param_temp_hot, param_rain_no, param_rain_yes);
		  $display("Resuming sensor readings...\n");
		  
		  soil_voltage_mv = 1500;
		  dht11_voltage_mv = 3300;
		  rain_voltage_mv = 1000;
		  #10;  // Allow outputs to stabilize

		  $display($time,
		  " Soil Digital: %d, Temp Digital: %d, Rain Digital: %d, Rain Present: %b, Irrigation Time: %d s, Pump On: %b, Sensor Enable: %b, Watering In Progress: %b, Countdown Timer: %d s, LCD Data (SOIL: %d, TEMP: %d, RAIN: %d, Message: %s)\n",
		  soil_digital, dht11_digital, rain_digital, rain_present, irrigation_time, pump_on, sensor_enable, watering_in_progress, watering_timer,
		  lcd_data[23:16], lcd_data[15:8], lcd_data[7:0], lcd_message_data); // Extract each 8-bit segment
		  
		  $stop;

end

endmodule