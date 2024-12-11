module soil_moisture_fsm (
    input wire clk,               // Clock signal
    input wire reset,             // Reset signal
    input wire start,             // Start signal (input)
    input wire measurement_done,  // Complete signal from ADC
    input wire moisture_low,      // Moisture threshold comparison (0: low, 1: sufficient)
    output reg pump_on            // Output to control pump (1: ON, 0: OFF)
);

    // State encoding using parameters
    parameter IDLE    = 2'b00;
    parameter MEASURE = 2'b01;
    parameter CONTROL = 2'b10;

    reg [1:0] current_state, next_state; // Current and next state variables

    // State transition logic (combinational logic block)
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (start) 
                    next_state = MEASURE; // Transition to MEASURE on start signal
                else 
                    next_state = IDLE;    // Remain in IDLE
            end
            
            MEASURE: begin
                if (measurement_done) 
                    next_state = CONTROL; // Transition to CONTROL after measurement completes
                else 
                    next_state = MEASURE; // Remain in MEASURE
            end
            
            CONTROL: begin
                if (moisture_low) 
                    next_state = CONTROL; // Stay in CONTROL if soil moisture is low
                else 
                    next_state = IDLE;    // Transition to IDLE if moisture is sufficient
            end
            
            default: 
                next_state = IDLE;        // Default state is IDLE
        endcase
    end

    // Sequential logic for state update (flip-flop behavior)
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;   // Reset state to IDLE
        else
            current_state <= next_state; // Update current state to next state
    end

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
