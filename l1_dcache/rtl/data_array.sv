module data_array #(
  parameter LINE_W = 512,
  parameter NUM_SETS = 64,
  parameter NUM_WAYS = 4
)(
  input  logic clk,
  input  logic we,
  input  logic [$clog2(NUM_SETS)-1:0] index,
  input  logic [$clog2(NUM_WAYS)-1:0] way,
  input  logic [LINE_W-1:0] line_in,

  output logic [LINE_W-1:0] line_out [NUM_WAYS]
);

  logic [LINE_W-1:0] data_mem [NUM_SETS][NUM_WAYS];

  always_ff @(posedge clk) begin
    if (we)
      data_mem[index][way] <= line_in;
  end

  always_comb begin
    for (int w = 0; w < NUM_WAYS; w++)
      line_out[w] = data_mem[index][w];
  end

endmodule
