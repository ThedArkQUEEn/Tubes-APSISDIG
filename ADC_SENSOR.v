module ADC_SENSOR #(parameter RESOLUTION = 10, VREF_MV = 5000)(
    input clk,
    input reset,
    input [15:0] soil_voltage_mv,
    input [15:0] dht11_voltage_mv,
    input [15:0] rain_voltage_mv,
    input sensor_enable,
    output [RESOLUTION-1:0] soil_digital,
    output [RESOLUTION-1:0] dht11_digital,
    output [RESOLUTION-1:0] rain_digital
);


    SOIL_ADC #(RESOLUTION, VREF_MV) soil_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(soil_voltage_mv),
        .digital_output(soil_digital),
        .sensor_enable(sensor_enable)
    );

    DHT11_ADC #(RESOLUTION, VREF_MV) dht11_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(dht11_voltage_mv),
        .digital_output(dht11_digital),
        .sensor_enable(sensor_enable)
    );

    RAIN_ADC #(RESOLUTION, VREF_MV) rain_adc (
        .clk(clk),
        .reset(reset),
        .analog_voltage_mv(rain_voltage_mv),
        .digital_output(rain_digital),
        .sensor_enable(sensor_enable)
    );

endmodule

module SOIL_ADC #(parameter RESOLUTION = 10, VREF_MV = 5000)(
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