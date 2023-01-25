`include "timescale.vh"

module cnn_core (
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_cnn_bias      ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_fmap             
    );
`include "defines_cnn_core.vh"

localparam LATENCY = 1;

// Input/Output declaration
input                               clk;
input                               reset_n;
input                               i_soft_reset;
input     [CO*CI*KX*KY*W_BW-1 : 0]  i_cnn_weight;
input     [CO*B_BW-1    : 0]  		i_cnn_bias;
input                               i_in_valid;
input     [CI*KX*KY*I_F_BW-1 : 0]  	i_in_fmap;
output                              o_ot_valid;
output    [CO*O_F_BW-1 : 0]  		o_ot_fmap;

// Data Enable Signals 
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
wire    [CO-1 : 0]          w_ot_valid;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid   <= {LATENCY{1'b0}};
    end else if(i_soft_reset) begin
        r_valid   <= {LATENCY{1'b0}};
    end else begin
        r_valid[LATENCY-1]  <= &w_ot_valid;
    end
end

assign	ce = r_valid;

// acc ci instance
wire    [CO-1 : 0]              w_in_valid;
wire    [CO*ACI_BW-1 : 0]  	w_ot_ci_acc;

genvar i;
generate
	for(i = 0; i < CO; i = i + 1) begin : output_channel
		wire    [CI*KX*KY*W_BW-1 : 0]  	w_cnn_weight 	= i_cnn_weight[i*CI*KY*KX*W_BW +: CI*KY*KX*W_BW];
		wire    [CI*KX*KY*I_F_BW-1 : 0] w_in_fmap    	= i_in_fmap;
		assign	w_in_valid[i] = i_in_valid;

		cnn_acc_ci u_cnn_acc_ci(
	    .clk             (clk         ),
	    .reset_n         (reset_n     ),
	    .i_soft_reset    (i_soft_reset),
	    .i_cnn_weight    (w_cnn_weight),
	    .i_in_valid      (w_in_valid[i]),
	    .i_in_fmap       (w_in_fmap),
	    .o_ot_valid      (w_ot_valid[i]),
	    .o_ot_ci_acc     (w_ot_ci_acc[i*ACI_BW +: ACI_BW])         
	    );
	end
endgenerate

// add_bias = acc + bias
wire      [CO*AB_BW-1 : 0]   add_bias  ;
reg       [CO*AB_BW-1 : 0]   r_add_bias;

genvar  j;
generate
    for (j = 0; j < CO; j = j + 1) begin : add_bias
        assign  add_bias[j*AB_BW +: AB_BW] = w_ot_ci_acc[j*ACI_BW +: ACI_BW] + i_cnn_bias[j*B_BW +: B_BW];

        always @(posedge clk or negedge reset_n) begin
            if(!reset_n) begin
                r_add_bias[add_idx*AB_BW +: AB_BW] <= {AB_BW{1'b0}};
            end else if(i_soft_reset) begin
                r_add_bias[add_idx*AB_BW +: AB_BW] <= {AB_BW{1'b0}};
            end else if(&w_ot_valid) begin
                r_add_bias[j*AB_BW +: AB_BW] <= add_bias[j*AB_BW +: AB_BW];
            end
        end
    end
endgenerate

//Activation Function
//no activation function here


assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_fmap  = r_add_bias;

endmodule

