module dcache_controller #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter TAG_W  = 20,
  parameter INDEX_W = 6,
  parameter OFFSET_W = 6,
  parameter NUM_WAYS = 4,
  parameter NUM_MSHR = 4
)(
  input  logic clk,
  input  logic rst_n,

  // CPU
  input  logic cpu_req_valid,
  input  logic cpu_req_rw,
  input  logic [ADDR_W-1:0] cpu_req_addr,
  input  logic [DATA_W-1:0] cpu_req_wdata,
  input  logic [DATA_W/8-1:0] cpu_req_wmask,

  output logic cpu_resp_valid,
  output logic [DATA_W-1:0] cpu_resp_rdata,
  output logic cpu_stall,

  // Memory
  output logic mem_req_valid,
  output logic [ADDR_W-1:0] mem_req_addr,
  input  logic mem_resp_valid,
  input  logic [511:0] mem_resp_data
);

  //----------------------------------------
  // Address fields
  //----------------------------------------
  logic [TAG_W-1:0]   tag;
  logic [INDEX_W-1:0] index;
  logic [OFFSET_W-1:0] offset;

  assign offset = cpu_req_addr[OFFSET_W-1:0];
  assign index  = cpu_req_addr[OFFSET_W+INDEX_W-1:OFFSET_W];
  assign tag    = cpu_req_addr[ADDR_W-1:OFFSET_W+INDEX_W];

  //----------------------------------------
  // Tag & Data Arrays
  //----------------------------------------
  logic [TAG_W-1:0] tag_out   [NUM_WAYS];
  logic             valid_out [NUM_WAYS];
  logic [511:0]      data_out [NUM_WAYS];

  tag_array #(.TAG_W(TAG_W), .NUM_SETS(64), .NUM_WAYS(NUM_WAYS))
    tags (.clk(clk), .we(0), .index(index), .way(0), .tag_in('0),
          .tag_out(tag_out), .valid_out(valid_out));

  data_array #(.LINE_W(512), .NUM_SETS(64), .NUM_WAYS(NUM_WAYS))
    data (.clk(clk), .we(0), .index(index), .way(0), .line_in('0),
          .line_out(data_out));

  //----------------------------------------
  // Tag match
  //----------------------------------------
  logic hit;
  logic [$clog2(NUM_WAYS)-1:0] hit_way;

  always_comb begin
    hit = 0;
    hit_way = 0;
    for (int w = 0; w < NUM_WAYS; w++) begin
      if (valid_out[w] && tag_out[w] == tag) begin
        hit = 1;
        hit_way = w;
      end
    end
  end

  //----------------------------------------
  // MSHR
  //----------------------------------------
  logic mshr_hit, mshr_full;
  logic [$clog2(NUM_MSHR)-1:0] mshr_id;

  mshr #(.NUM_MSHR(NUM_MSHR)) mshr_u (
    .clk(clk), .rst_n(rst_n),
    .miss_valid(cpu_req_valid && !hit),
    .miss_addr(cpu_req_addr),
    .miss_is_store(cpu_req_rw),
    .miss_store_data(cpu_req_wdata),
    .miss_store_mask(cpu_req_wmask),
    .mshr_hit(mshr_hit),
    .mshr_full(mshr_full),
    .mshr_hit_id(mshr_id),
    .alloc_fire(),
    .alloc_id(),
    .mem_refill_valid(mem_resp_valid),
    .mem_refill_id('0),
    .refill_done(),
    .refill_done_id()
  );

  //----------------------------------------
  // Control
  //----------------------------------------
  always_comb begin
    cpu_resp_valid = 0;
    cpu_resp_rdata = '0;
    cpu_stall      = 0;
    mem_req_valid  = 0;
    mem_req_addr   = '0;

    if (cpu_req_valid) begin
      if (hit) begin
        cpu_resp_valid = 1;
        cpu_resp_rdata =
          data_out[hit_way] >> (offset * 8);
      end
      else if (!mshr_full) begin
        mem_req_valid = 1;
        mem_req_addr  = {cpu_req_addr[ADDR_W-1:OFFSET_W], {OFFSET_W{1'b0}}};
        cpu_stall     = 1;
      end
      else begin
        cpu_stall = 1;
      end
    end
  end

endmodule
