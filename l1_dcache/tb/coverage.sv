covergroup cache_cg @(posedge clk);
  coverpoint cpu_req_valid;
  coverpoint cpu_stall;
  coverpoint mem_req_valid;
  coverpoint mem_resp_valid;

  cross cpu_req_valid, cpu_stall;
endgroup

cache_cg cg = new();
