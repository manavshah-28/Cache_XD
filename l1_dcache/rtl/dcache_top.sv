//======================================================
// L1 Data Cache Top Level
// Non-blocking, Write-back, Write-allocate
//======================================================

module dcache_top #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32,
  parameter int LINE_BYTES = 64,
  parameter int NUM_WAYS = 4,
  parameter int NUM_SETS = 64,
  parameter int NUM_MSHR = 4
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // CPU interface
  input  logic                 cpu_req_valid,
  input  logic                 cpu_req_rw,       // 0=read, 1=write
  input  logic [ADDR_W-1:0]     cpu_req_addr,
  input  logic [DATA_W-1:0]     cpu_req_wdata,
  input  logic [DATA_W/8-1:0]   cpu_req_wmask,

  output logic                 cpu_resp_valid,
  output logic [DATA_W-1:0]     cpu_resp_rdata,
  output logic                 cpu_stall,

  // Memory interface
  output logic                 mem_req_valid,
  output logic [ADDR_W-1:0]     mem_req_addr,
  input  logic                 mem_resp_valid,
  input  logic [LINE_BYTES*8-1:0] mem_resp_data
);

  // ----------------------------------------
  // Address breakdown
  // ----------------------------------------
  localparam int OFFSET_W = $clog2(LINE_BYTES);
  localparam int INDEX_W  = $clog2(NUM_SETS);
  localparam int TAG_W    = ADDR_W - OFFSET_W - INDEX_W;

  logic [TAG_W-1:0]   req_tag;
  logic [INDEX_W-1:0] req_index;
  logic [OFFSET_W-1:0] req_offset;

  assign req_offset = cpu_req_addr[OFFSET_W-1:0];
  assign req_index  = cpu_req_addr[OFFSET_W + INDEX_W -1 : OFFSET_W];
  assign req_tag    = cpu_req_addr[ADDR_W-1 : OFFSET_W + INDEX_W];

  // ----------------------------------------
  // Wires between submodules
  // ----------------------------------------
  logic cache_hit;
  logic [$clog2(NUM_WAYS)-1:0] hit_way;

  logic mshr_hit, mshr_full;
  logic [$clog2(NUM_MSHR)-1:0] mshr_id;

  // ----------------------------------------
  // Instantiate controller
  // ----------------------------------------
  dcache_controller #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .TAG_W(TAG_W),
    .INDEX_W(INDEX_W),
    .OFFSET_W(OFFSET_W),
    .NUM_WAYS(NUM_WAYS),
    .NUM_MSHR(NUM_MSHR)
  ) controller (
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

endmodule
