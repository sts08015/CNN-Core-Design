`include "timescale.vh"
module cnn_kernel (
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_kernel_acc              
    );
`include "defines_cnn_core.vh"
localparam LATENCY = 2;

input                           clk;
input                           reset_n;
input                           i_soft_reset;
input   [KX*KY*W_BW-1 : 0]      i_cnn_weight;
input                           i_in_valid;
input   [KX*KY*I_F_BW-1 : 0]    i_in_fmap;
output                          o_ot_valid;
output  [AK_BW-1 : 0]           o_ot_kernel_acc ;

// Data Enable Signals 
wire    [LATENCY-1 : 0] ce;
reg     [LATENCY-1 : 0] r_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid   <= {LATENCY{1'b0}};
    end else if(i_soft_reset) begin
        r_valid   <= {LATENCY{1'b0}};
    end else begin
        r_valid[LATENCY-2]  <= i_in_valid;
        r_valid[LATENCY-1]  <= r_valid[LATENCY-2];
    end
end

assign	ce = r_valid;

// mul = fmap * weight
wire    [KY*KX*M_BW-1 : 0]  mul;
reg     [KY*KX*M_BW-1 : 0]  r_mul;

genvar i;
generate
    for(i=0;i<KY*KX;i=i+1) begin : element_wise_mul
        mul[i*M_BW +: M_BW] = i_in_fmap[i*I_F_BW +: I_F_BW] * i_cnn_weight[i*W_BW +: W_BW];
        always@(posedge clk or negedge reset_n) begin
            if(!reset_n) begin
                r_mul[i*M_BW +: M_BW] <= {M_BW{1'b0}};
            end else if(i_soft_reset) begin
                r_mul[i*M_BW +: M_BW] <= {M_BW{1'b0}};
            end else begin
                r_mul[i*M_BW +: M_BW] <= mul[i*M_BW +: M_BW];
            end
        end
    end
endgenerate

reg [AK_BW-1 : 0]   acc_kernel   ;
reg [AK_BW-1 : 0]   r_acc_kernel ;

integer j;
generate
    always @(*) begin
        for(j=0; j < KY*KX; j = j + 1) begin
            acc_kernel += r_mul[j*M_BW +: M_BW];
        end
    end

    always @(posedge clk or negedge reset_n) begin
	    if(!reset_n) begin
	        r_acc_kernel <= {AK_BW{1'b0}};
	    end else if(i_soft_reset) begin
	        r_acc_kernel <= {AK_BW{1'b0}};
	    end else if(ce[LATENCY-2]) begin
	        r_acc_kernel <= acc_kernel;
	    end
	end
endgenerate

assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_kernel_acc = r_acc_kernel;

endmodule
