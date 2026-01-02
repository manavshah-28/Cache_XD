module tag_array #(
  parameter TAG_W = 20,
  parameter NUM_SETS = 64,
  parameter NUM_WAYS = 4
)(
  input  logic clk,
  input  logic we,
  input  logic [$clog2(NUM_SETS)-1:0] index,
  input  logic [$clog2(NUM_WAYS)-1:0] way,
  input  logic [TAG_W-1:0] tag_in,

  output logic [TAG_W-1:0] tag_out [NUM_WAYS],
  output logic             valid_out [NUM_WAYS]
);

  logic [TAG_W-1:0] tag_mem   [NUM_SETS][NUM_WAYS];
  logic             valid_mem [NUM_SETS][NUM_WAYS];

  always_ff @(posedge clk) begin
    if (we) begin
      tag_mem[index][way]   <= tag_in;
      valid_mem[index][way] <= 1'b1;
    end
  end

  always_comb begin
    for (int w = 0; w < NUM_WAYS; w++) begin
      tag_out[w]   = tag_mem[index][w];
      valid_out[w] = valid_mem[index][w];
    end
  end

endmodule
