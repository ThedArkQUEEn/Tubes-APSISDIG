module soil_moisture_fsm_output (
    input wire moisture_low,      // Moisture threshold comparison (0: low, 1: sufficient)
    input wire [1:0] current_state, // Current state
    output reg pump_on            // Output to control pump (1: ON, 0: OFF)
);

    // State encoding using parameters
    parameter IDLE    = 2'b00;
    parameter MEASURE = 2'b01;
    parameter CONTROL = 2'b10;

    // Output logic (combinational logic block)
    always @(*) begin
        pump_on = 1'b0; // Default output (pump OFF)
        case (current_state)
            CONTROL: begin
                if (moisture_low) 
                    pump_on = 1'b1; // Turn pump ON if moisture is low
            end
            default: 
                pump_on = 1'b0; // Pump remains OFF in other states
        endcase
    end

endmodule
