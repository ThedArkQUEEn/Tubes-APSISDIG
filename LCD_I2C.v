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
    reg [1:0] message_state;
    reg [15:0] message_timer;

    parameter MESSAGE_CYCLE_TIME = 1000;

    always @(*) begin
        soil_scaled = (soil_digital * 255) / 1023;
        temp_scaled = (dht11_digital * 255) / 1023;
        rain_scaled = (rain_digital * 255) / 1023;
        lcd_data = {soil_scaled, temp_scaled, rain_scaled};
    end

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        message_state <= 0;
        message_timer <= 0;
        lcd_message_data <= 24'h4e554c;
    end else begin
        if (watering_in_progress) begin
            if (message_timer >= MESSAGE_CYCLE_TIME) begin
                message_timer <= 0;
                message_state <= (message_state + 1) % 2; // Cycle through "WAT" and "DON"
					 if (watering_in_progress == 0) begin
						  lcd_message_data <= 24'h444f4e;
					 end
            end else begin
                message_timer <= message_timer + 1;
            end

            case (message_state)
                0: lcd_message_data <= 24'h574154; // "WAT"
                1: lcd_message_data <= 24'h444f4e; // "DON"
            endcase
        end else begin
            message_state <= 0;
            message_timer <= 0;
            lcd_message_data <= 24'h49444c; // "IDL"
        end
    end
end

    always @(posedge clk) begin
        sda <= lcd_message_data[0];
        scl <= ~sda;
    end
endmodule