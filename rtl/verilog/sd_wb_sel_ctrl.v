//////////////////////////////////////////////////////////////////////
////                                                              ////
//// WISHBONE SD Card Controller IP Core                          ////
////                                                              ////
//// sd_wb_sel_ctrl.v                                             ////
////                                                              ////
//// This file is part of the WISHBONE SD Card                    ////
//// Controller IP Core project                                   ////
//// http://opencores.org/project,sd_card_controller              ////
////                                                              ////
//// Description                                                  ////
//// Module resposible for controlling wb_sel signal of the       ////
//// master wishbone if. Handles unaligned access to wishbone     ////
//// bus.                                                         ////
////                                                              ////
//// Author(s):                                                   ////
////     - Marek Czerski, ma.czerski@gmail.com                    ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2013 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE. See the GNU Lesser General Public License for more  ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
`include "sd_defines.h"

module sd_wb_sel_ctrl(
           input wb_clk,
           input rst,
           input ena,
           input [31:0] base_adr_i,
           input [31:0] wbm_adr_i,
           input [`BLKSIZE_W-1:0] blksize,
           output [3:0] wbm_sel_o
       );

function [3:0] get_first_sel;
    input [1:0] byte_addr;
    begin
        case (byte_addr)
            2'b00: get_first_sel = 4'b1111;
            2'b01: get_first_sel = 4'b0111;
            2'b10: get_first_sel = 4'b0011;
            2'b11: get_first_sel = 4'b0001;
        endcase
    end
endfunction

function [3:0] get_last_sel;
    input [1:0] byte_addr;
    begin
        case (byte_addr)
            2'b00: get_last_sel = 4'b1111;
            2'b01: get_last_sel = 4'b1000;
            2'b10: get_last_sel = 4'b1100;
            2'b11: get_last_sel = 4'b1110;
        endcase
    end
endfunction

reg [31:0] base_adr_reg;
reg [31:0] blksize_reg;
wire [31:0] base_adr_plus_blksize;

wire [3:0] first_mask, second_mask;

assign base_adr_plus_blksize = base_adr_reg + blksize_reg;
assign first_mask = base_adr_reg[31:2] == wbm_adr_i[31:2] ?
                    get_first_sel(base_adr_i[1:0]) :
                    4'b1111;
assign second_mask = base_adr_plus_blksize[31:2] == wbm_adr_i[31:2] ?
                   get_last_sel(base_adr_plus_blksize[1:0]) :
                   4'b1111;
assign wbm_sel_o = first_mask & second_mask;

always @(posedge wb_clk or posedge rst)
    if (rst) begin
        base_adr_reg <= 0;
        blksize_reg <= 0;
    end
    else begin
        if (!ena) begin
            $display("blksize == %x", blksize);
            base_adr_reg <= base_adr_i;
            blksize_reg <= blksize;
        end
        else begin
            $display("blksize_reg == %x", blksize_reg);
            if (wbm_adr_i == base_adr_reg + blksize)
                base_adr_reg <= base_adr_reg + blksize;
        end
    end

endmodule

    