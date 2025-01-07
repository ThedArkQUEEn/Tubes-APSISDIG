module Penyiraman_Otomatis (
    input clk,
    input reset,
    input [7:0] irrigation_time,
    output reg pump_on,
    output reg sensor_enable,
    output reg watering_in_progress,
    output reg [7:0] watering_timer
);

    reg [7:0] timer_count;
    reg irrigation_active;
	 
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pump_on <= 0;
            sensor_enable <= 1;
            watering_in_progress <= 0;
            watering_timer <= 0;
            timer_count <= 0;
            irrigation_active <= 0;
        end else begin
            if (irrigation_active) begin
                if (timer_count > 0) begin
                    timer_count <= timer_count - 1;
                    watering_timer <= timer_count;
						  sensor_enable <= 0;
                end else begin
                    pump_on <= 0;
                    sensor_enable <= 1;
                    watering_in_progress <= 0;
                    irrigation_active <= 0;
                    watering_timer <= 0;
                end
            end else begin
                if (irrigation_time > 0) begin
                    pump_on <= 1;
                    sensor_enable <= 0;
                    watering_in_progress <= 1;
                    irrigation_active <= 1;
                    timer_count <= irrigation_time;
                    watering_timer <= irrigation_time;
                end
            end
        end
    end

endmodule