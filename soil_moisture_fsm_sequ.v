module soil_moisture_fsm_sequ (
    input wire clk,               // Clock signal
    input wire reset,             // Reset signal
    input wire [1:0] next_state,  // Next state from combinational logic
    output reg [1:0] current_state // Current state
);

    // State encoding using parameters
    parameter IDLE    = 2'b00;
    parameter MEASURE = 2'b01;
    parameter CONTROL = 2'b10;

    // Sequential logic for state update (flip-flop behavior)
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= IDLE;   // Reset state to IDLE
        else
            current_state <= next_state; // Update current state to next state
    end

endmodule
