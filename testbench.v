module testbench;
    // Testbench signals
    reg clk;
    reg reset;
    reg start;
    reg measurement_done;
    reg moisture_low;
    wire pump_on;

    // Instantiate the FSM module
    soil_moisture_fsm uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .measurement_done(measurement_done),
        .moisture_low(moisture_low),
        .pump_on(pump_on)
    );

    // Clock generation
    always begin
        #5 clk = ~clk; // 10ns period
    end

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        start = 0;
        measurement_done = 0;
        moisture_low = 0;

        // Apply reset
        reset = 1;
        #10 reset = 0;

        // Start the FSM
        start = 1;
        #10 start = 0;

        // Simulate measurement done
        measurement_done = 1;
        #10 measurement_done = 0;

        // Simulate low moisture level
        moisture_low = 1;
        #10 moisture_low = 0;

        // Finish simulation
        #100 $finish;
    end

    // Display output
    initial begin
        $monitor("At time %t, pump_on = %b", $time, pump_on);
    end
endmodule
