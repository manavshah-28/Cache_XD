module dcache_tb;

  logic clk, rst_n;

  // CPU
  logic cpu_req_valid;
  logic cpu_req_rw;
  logic [31:0] cpu_req_addr;
  logic [31:0] cpu_req_wdata;
  logic [3:0]  cpu_req_wmask;

  logic cpu_resp_valid;
  logic [31:0] cpu_resp_rdata;
  logic cpu_stall;

  // Memory
  logic mem_req_valid;
  logic [31:0] mem_req_addr;
  logic mem_resp_valid;
  logic [511:0] mem_resp_data;

  //----------------------------------------
  // DUT
  //----------------------------------------
  dcache_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_req_valid(cpu_req_valid),
    .cpu_req_rw(cpu_req_rw),
    .cpu_req_addr(cpu_req_addr),
    .cpu_req_wdata(cpu_req_wdata),
    .cpu_req_wmask(cpu_req_wmask),
    .cpu_resp_valid(cpu_resp_valid),
    .cpu_resp_rdata(cpu_resp_rdata),
    .cpu_stall(cpu_stall),
    .mem_req_valid(mem_req_valid),
    .mem_req_addr(mem_req_addr),
    .mem_resp_valid(mem_resp_valid),
    .mem_resp_data(mem_resp_data)
  );

  //----------------------------------------
  // Memory model
  //----------------------------------------
  simple_mem mem (
    .clk(clk),
    .req_valid(mem_req_valid),
    .req_addr(mem_req_addr),
    .resp_valid(mem_resp_valid),
    .resp_data(mem_resp_data)
  );

  //----------------------------------------
  // Clock
  //----------------------------------------
  always #5 clk = ~clk;

  //----------------------------------------
  // Test sequence
  //----------------------------------------
  initial begin
    clk = 0;
    rst_n = 0;
    cpu_req_valid = 0;
    #20 rst_n = 1;

    // Load miss
    send_load(32'h1000);

    // Hit-under-miss
    send_load(32'h1004);

    // Another miss
    send_load(32'h2000);

    #200 $finish;
  end

  task send_load(input [31:0] addr);
    begin
      @(posedge clk);
      cpu_req_valid = 1;
      cpu_req_rw = 0;
      cpu_req_addr = addr;
      cpu_req_wmask = 0;
      @(posedge clk);
      cpu_req_valid = 0;
    end
  endtask

endmodule
