module soil_moisture_fsm_comb (
    input wire start,             // Start signal (input)
    input wire measurement_done,  // Complete signal from ADC
    input wire moisture_low,      // Moisture threshold comparison (0: low, 1: sufficient)
    input wire [1:0] current_state, // Current state
    output reg [1:0] next_state   // Next state
);
    // State encoding using parameters
    parameter IDLE    = 2'b00;
    parameter MEASURE = 2'b01;
    parameter CONTROL = 2'b10;

    // State transition logic (combinational)
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

endmodule
