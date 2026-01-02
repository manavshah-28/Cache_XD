//======================================================
// Miss Status Holding Register (MSHR)
// Supports multiple outstanding misses and miss merging
//======================================================

module mshr #(
  parameter int ADDR_W    = 32,
  parameter int DATA_W    = 32,
  parameter int LINE_BYTES = 64,
  parameter int NUM_MSHR  = 4
)(
  input  logic clk,
  input  logic rst_n,

  // Miss request from cache
  input  logic               miss_valid,
  input  logic [ADDR_W-1:0]  miss_addr,
  input  logic               miss_is_store,
  input  logic [DATA_W-1:0]  miss_store_data,
  input  logic [DATA_W/8-1:0] miss_store_mask,

  // Status outputs
  output logic               mshr_hit,
  output logic               mshr_full,
  output logic [$clog2(NUM_MSHR)-1:0] mshr_hit_id,

  // Allocate signal
  output logic               alloc_fire,
  output logic [$clog2(NUM_MSHR)-1:0] alloc_id,

  // Memory interface tracking
  input  logic               mem_refill_valid,
  input  logic [$clog2(NUM_MSHR)-1:0] mem_refill_id,

  // Refill done indication
  output logic               refill_done,
  output logic [$clog2(NUM_MSHR)-1:0] refill_done_id
);

  // ----------------------------------------
  // Address breakdown
  // ----------------------------------------
  localparam int OFFSET_W = $clog2(LINE_BYTES);
  localparam int LINE_ADDR_W = ADDR_W - OFFSET_W;

  logic [LINE_ADDR_W-1:0] miss_line_addr;
  assign miss_line_addr = miss_addr[ADDR_W-1:OFFSET_W];

  // ----------------------------------------
  // MSHR entry definition
  // ----------------------------------------
  typedef struct packed {
    logic                   valid;
    logic [LINE_ADDR_W-1:0] line_addr;
    logic                   is_store;
    logic [DATA_W-1:0]      store_data;
    logic [DATA_W/8-1:0]    store_mask;
    logic                   waiting_mem;
  } mshr_entry_t;

  mshr_entry_t mshr_table[NUM_MSHR];

  // ----------------------------------------
  // Lookup: detect MSHR hit (miss merging)
  // ----------------------------------------
  always_comb begin
    mshr_hit    = 1'b0;
    mshr_hit_id = '0;

    for (int i = 0; i < NUM_MSHR; i++) begin
      if (mshr_table[i].valid &&
          mshr_table[i].line_addr == miss_line_addr) begin
        mshr_hit    = 1'b1;
        mshr_hit_id = i[$clog2(NUM_MSHR)-1:0];
      end
    end
  end

  // ----------------------------------------
  // Find free MSHR
  // ----------------------------------------
  always_comb begin
    mshr_full = 1'b1;
    alloc_id  = '0;

    for (int i = 0; i < NUM_MSHR; i++) begin
      if (!mshr_table[i].valid) begin
        mshr_full = 1'b0;
        alloc_id  = i[$clog2(NUM_MSHR)-1:0];
        break;
      end
    end
  end

  assign alloc_fire = miss_valid && !mshr_hit && !mshr_full;

  // ----------------------------------------
  // Refill completion
  // ----------------------------------------
  assign refill_done    = mem_refill_valid;
  assign refill_done_id = mem_refill_id;

  // ----------------------------------------
  // Sequential logic
  // ----------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_MSHR; i++) begin
        mshr_table[i].valid       <= 1'b0;
        mshr_table[i].waiting_mem <= 1'b0;
      end
    end
    else begin

      // ----------------------------------
      // Allocate new MSHR
      // ----------------------------------
      if (alloc_fire) begin
        mshr_table[alloc_id].valid       <= 1'b1;
        mshr_table[alloc_id].line_addr   <= miss_line_addr;
        mshr_table[alloc_id].is_store    <= miss_is_store;
        mshr_table[alloc_id].store_data  <= miss_store_data;
        mshr_table[alloc_id].store_mask  <= miss_store_mask;
        mshr_table[alloc_id].waiting_mem <= 1'b1;
      end

      // ----------------------------------
      // Memory refill completed
      // ----------------------------------
      if (mem_refill_valid) begin
        mshr_table[mem_refill_id].waiting_mem <= 1'b0;
        mshr_table[mem_refill_id].valid       <= 1'b0;
      end

    end
  end

endmodule
