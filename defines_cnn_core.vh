parameter   CI          = 3;  // Input Channel # 
parameter   CO          = 16; // Output Channel #
parameter	KX			= 3;  // Kernel X size
parameter	KY			= 3;  // Kernel Y size

parameter   I_F_BW      = 8;  // Input Feature bit width
parameter   W_BW        = 8;  // Weight bit width
parameter   B_BW        = 8;  // Bias bit width

parameter   M_BW        = 16; // I_F_BW * W_BW
parameter   AK_BW       = 20; // M_BW + log(KY*KX) Accum Kernel 
parameter   ACI_BW		= 22; // AK_BW + log (CI) Accum Channel Input
parameter   AB_BW       = 23; // ACI_BW + bias (#1). 
parameter   O_F_BW      = 23; // No Activation, So O_F_BW == AB_BW
