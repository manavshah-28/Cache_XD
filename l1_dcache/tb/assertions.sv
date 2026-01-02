// Memory request must eventually get response
property mem_eventually_responds;
  @(posedge clk)
  mem_req_valid |-> ##[1:10] mem_resp_valid;
endproperty

assert property (mem_eventually_responds);

// CPU cannot get response while stalled
property no_resp_while_stall;
  @(posedge clk)
  cpu_stall |-> !cpu_resp_valid;
endproperty

assert property (no_resp_while_stall);
