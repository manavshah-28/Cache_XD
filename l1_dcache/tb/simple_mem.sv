module simple_mem #(
  parameter ADDR_W = 32,
  parameter LINE_W = 512
)(
  input  logic clk,
  input  logic req_valid,
  input  logic [ADDR_W-1:0] req_addr,

  output logic resp_valid,
  output logic [LINE_W-1:0] resp_data
);

  logic [2:0] delay_cnt;

  always_ff @(posedge clk) begin
    if (req_valid) begin
      delay_cnt <= 3'd4; // fixed latency
    end else if (delay_cnt != 0) begin
      delay_cnt <= delay_cnt - 1;
    end

    resp_valid <= (delay_cnt == 1);
  end

  always_comb begin
    // deterministic data for debug
    resp_data = {16{req_addr}};
  end

endmodule
