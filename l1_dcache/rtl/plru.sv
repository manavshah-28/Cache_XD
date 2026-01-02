module plru #(
  parameter NUM_WAYS = 4
)(
  input  logic clk,
  input  logic update,
  input  logic [$clog2(NUM_WAYS)-1:0] hit_way,
  output logic [$clog2(NUM_WAYS)-1:0] victim
);

  logic [NUM_WAYS-2:0] tree; // 3 bits for 4-way

  always_ff @(posedge clk) begin
    if (update) begin
      case (hit_way)
        0: tree <= 3'b110;
        1: tree <= 3'b100;
        2: tree <= 3'b001;
        3: tree <= 3'b000;
      endcase
    end
  end

  always_comb begin
    victim = tree[0] ? (tree[2] ? 3 : 2) :
                       (tree[1] ? 1 : 0);
  end

endmodule
