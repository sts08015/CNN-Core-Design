`include "timescale.vh"

module cnn_acc_ci (
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_ci_acc              
    );
`include "defines_cnn_core.vh"
localparam LATENCY = 1;

input                           clk;
input                           reset_n;
input                           i_soft_reset;
input   [CI*KX*KY*W_BW-1 : 0]   i_cnn_weight;
input                           i_in_valid;
input   [CI*KX*KY*I_F_BW-1 : 0] i_in_fmap;
output                          o_ot_valid;
output  [ACI_BW-1 : 0]          o_ot_ci_acc;

// Data Enable Signals 
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
wire    [CI-1 : 0]          w_ot_valid; //to check output of each channel is valid
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid   <= {LATENCY{1'b0}};
    end else if(i_soft_reset) begin
        r_valid   <= {LATENCY{1'b0}};
    end else begin
        r_valid[LATENCY-1]  <= &w_ot_valid; // if output of every channel is valid
    end
end

assign	ce = r_valid;

// MAC kernel instance
wire    [CI-1 : 0]              w_in_valid;
wire    [CI*AK_BW-1 : 0]  		w_ot_kernel_acc;
wire    [ACI_BW-1 : 0]  		w_ot_ci_acc;
reg     [ACI_BW-1 : 0]  		r_ot_ci_acc;
reg     [ACI_BW-1 : 0]  		ot_ci_acc;

genvar i;
generate
    for(i=0;i<CI;i=i+1) begin : cnn_kernel
        wire [KX*KY*W_BW-1 : 0] w_cnn_weight = i_cnn_weight[i*KX*KY*W_BW +: KX*KY*W_BW];
        wire [KX*KY*I_F_BW-1 : 0] w_in_fmap = i_in_fmap[i*KY*KX*I_F_BW +: KY*KX*I_F_BW];
		assign	w_in_valid[i] = i_in_valid;

        cnn_kernel res( .clk(clk),
                        .reset_n(reset_n),
                        .i_soft_reset(i_soft_reset),
                        .i_cnn_weight(w_cnn_weight),
                        .i_in_valid(wi_in_valid[i]),
                        .i_in_fmap(w_in_fmap),
                        .o_ot_valid(w_ot_valid[i]),
                        .o_ot_kernel_acc(w_ot_kernel_acc[i*AK_BW+:AK_BW])
                        );
    end
endgenerate

reg [ACI_BW-1 : 0] ot_ci_acc;
integer j;
always @(*) begin
    for(j=0;j<CI;j++) begin
        ot_ci_acc += w_ot_kernel_acc[j*AK_BW+:AK_BW];
    end
end

assign w_ot_ci_acc = ot_ci_acc;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_ot_ci_acc <= {ACI_BW{1'b0}};
    end else if(i_soft_reset) begin
        r_ot_ci_acc <= {ACI_BW{1'b0}};
    end else if(&w_ot_valid)begin
        r_ot_ci_acc <= w_ot_ci_acc;
    end
end

assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_ci_acc = r_ot_ci_acc;

endmodule
