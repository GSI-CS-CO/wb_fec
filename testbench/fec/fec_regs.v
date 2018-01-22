// WB Addres of the WB Enable Encoder/Decoder
`define FEC_ENC_EN                   1'h0
// WB Address of the WB Dropper Interface
`define DROPP                        1'h0
// FEC Errors
// The FEC packet 0 and 1 are use for decoding
// no packets are dropped
`define X01                          4'h0
// The FEC packet 0 and 2 are use for decoding
// packet FEC 1 is dropped in the Dropper module
`define X02                          4'h2
// The FEC packet 0 and 3 are use for decoding
// packet FEC 1 and 2 are dropped in the Dropper module
`define X03                          4'h6
// The FEC packet 1 and 2 are use for decoding
// packet FEC 0 is dropped in the Dropper module
`define X12                          4'h1
// The FEC packet 1 and 3 are use for decoding
// packet FEC 0 and 2 are dropped in the Dropper module
`define X13                          4'h5
// The FEC packet 2 and 3 are use for decoding
// packet FEC 0 and 1 are dropped in the Dropper module
`define X23                          4'h3
// No possible to decode more than 2 packets dropped
`define ERR                          4'hE

//`define LBK_MCR_ENA_OFFSET 0
//`define LBK_MCR_ENA 32'h00000001
//`define LBK_MCR_CLR_OFFSET 1
//`define LBK_MCR_CLR 32'h00000002
//`define LBK_MCR_FDMAC_OFFSET 2
//`define LBK_MCR_FDMAC 32'h00000004
//`define ADDR_LBK_DMAC_L                5'h4
//`define ADDR_LBK_DMAC_H                5'h8
//`define ADDR_LBK_RCV_CNT               5'hc
//`define ADDR_LBK_DRP_CNT               5'h10
//`define ADDR_LBK_FWD_CNT               5'h14
