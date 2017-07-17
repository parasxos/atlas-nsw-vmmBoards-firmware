`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Reid Pinkham
//
// Copyright Notice/Copying Permission:
//    Copyright 2017 Reid Pinkham
//
//    This file is part of NTUA-BNL_VMM_firmware.
//
//    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>. 
// 
// Create Date: 23.06.2016 16:57:10
// Design Name: 
// Module Name: xadc_read
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xadc_read
(
    input           clk125,
    input           rst,
    input           start,
    input   [4:0]   ch_sel,
    input           busy_xadc,
    input           drdy,
    input   [4:0]   channel,
    input   [15:0]  do_out,
    input           eoc,
    input           eos,

    output          done,
    output  [11:0]  result,
    output          convst,
    output  [6:0]   daddr,
    output          den,
    output          dwe,
    output  [15:0]  di,
    output          rst_xadc,
    output  [3:0]   mux_select
);


wire [1:0]      rw; // 01 for read, 10 for write
wire [6:0]      drp_addr;
wire            drp_done;

reg [3:0]       st_drp;
reg [3:0]       st;
reg             drp_done_r;
reg             den_r;
reg             dwe_r;
reg [6:0]       daddr_r;
reg [1:0]       rw_r;
reg [6:0]       drp_addr_r;
reg [15:0]      drp_data_out_r;
reg [15:0]      drp_data_in_r;
reg [15:0]      di_r;
reg [15:0]      config_reg_r;
reg             convst_r;
reg             done_r;
reg [11:0] result_r;
reg         first;
reg [5:0]   cnt_delay;
reg         rst_xadc_r;
reg [4:0]   config_in_r;
reg [4:0]   input_select_r;
reg [3:0]   mux_select_r;

parameter idle = 4'b0, st1 = 4'b1, st2 = 4'b10, st3 = 4'b11, st4 = 4'b100, st5 = 4'b101, st6 = 4'b110, st7 = 4'b111;
parameter st8 = 4'b1000, st9 = 4'b1001, st10 = 4'b1010, st11 = 4'b1011, st12 = 4'b1100, st13 = 4'b1101;
parameter st14 = 4'b1110, st15 = 4'b1111;


assign den = den_r;
assign dwe = dwe_r;
assign daddr = daddr_r;
assign drp_done = drp_done_r;
assign rw = rw_r;
assign drp_addr = drp_addr_r;
assign di = di_r;
assign convst = convst_r;
assign done = done_r;
assign result = result_r;
assign rst_xadc = rst_xadc_r;
assign mux_select = mux_select_r;



// Statement to latch the config_in_r state
always @(posedge clk125)
begin
    if (start == 1'b1)
        config_in_r <= ch_sel;
    else
        config_in_r <= config_in_r;
end

// Case statement to change outputs and mux state based on the ch_sel input
always @(config_in_r)
begin
    case (config_in_r)
        5'b00000 : begin input_select_r <= 5'h10; mux_select_r <= 4'b1000; end // PDO 0
        5'b00001 : begin input_select_r <= 5'h11; mux_select_r <= 4'b1000; end // PDO 1
        5'b00010 : begin input_select_r <= 5'h12; mux_select_r <= 4'b1000; end // PDO 2
        5'b00011 : begin input_select_r <= 5'h13; mux_select_r <= 4'b1000; end // PDO 3
        5'b00100 : begin input_select_r <= 5'h18; mux_select_r <= 4'b1000; end // PDO 4
        5'b00101 : begin input_select_r <= 5'h19; mux_select_r <= 4'b1000; end // PDO 5
        5'b00110 : begin input_select_r <= 5'h1a; mux_select_r <= 4'b1000; end // PDO 6
        5'b00111 : begin input_select_r <= 5'h1b; mux_select_r <= 4'b1000; end // PDO 7
        5'b10000 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0000; end // 1v2 0
        5'b10001 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0001; end // 1v2 1
        5'b10010 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0010; end // 1v2 2
        5'b10011 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0011; end // 1v2 3
        5'b10100 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0100; end // 1v2 4
        5'b10101 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0101; end // 1v2 5
        5'b10110 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0110; end // 1v2 6
        5'b10111 : begin input_select_r <= 5'h03; mux_select_r <= 4'b0111; end // 1v2 7
        5'b11000 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1000; end // TDO 0
        5'b11001 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1001; end // TDO 1
        5'b11010 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1010; end // TDO 2
        5'b11011 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1011; end // TDO 3
        5'b11100 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1100; end // TDO 4
        5'b11101 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1101; end // TDO 5
        5'b11110 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1110; end // TDO 6
        5'b11111 : begin input_select_r <= 5'h03; mux_select_r <= 4'b1111; end // TDO 7
        default : begin input_select_r <= 5'h03; mux_select_r <= 4'b1111; end // PDO 0 default
    endcase
end



// Main State Machine
always @(posedge clk125)
begin
    if (rst)
        begin
            st <= idle;
            done_r <= 1'b0;
            first <= 1'b0;
            cnt_delay <= 6'b0;
        end
    else if (1'b1)
    begin
    case (st)
        idle :
            begin
                done_r <= 1'b0;
                if (start == 1'b1) // read and save config reg 0
                    begin
                        if (first == 1'b1) // no need to configure to single channel mode
                            begin
                                st <= st4;
                                rw_r <= 2'b01; // read
                                drp_addr_r <= 7'h40; // Config 0
                            end
                        else // First time through
                            begin
                                st <= st1;
                                rw_r <= 2'b01; // read
                                drp_addr_r <= 7'h41; // Config 1
                            end
                    end
                else
                    st <= idle;
            end

        st1 : // Wait for read response, and save it
            begin
                rw_r <= 2'b0;
                if (drp_done == 1'b1)
                    begin
                        config_reg_r <= drp_data_out_r; // save configuration
                        st <= st2;
                    end
                else
                    st <= st1;
            end

        st2 : // Write new configuration
            begin
                rw_r <= 2'b10; // write
                drp_addr_r <= 7'h41; // Config 1
                drp_data_in_r <= {4'b0011, config_reg_r[11:0]}; // Single channel mode
                st <= st3;
            end

        st3 : // Wait for done, then wait for busy
            begin
                rw_r <= 2'b0;
                if (drp_done == 1'b1)
                    begin
                        first <= 1'b1;
                        st <= st4;
                    end
                else
                    st <= st3;
            end

        st4 : // wait for busy done, then contine as normal
            begin
                if (busy_xadc == 1'b0)
                    begin
                        rw_r <= 2'b01; // read
                        drp_addr_r <= 7'h40; // Config 0
                        st <= st5;
                    end
                else
                    st <= st4;
            end

        st5 : // Wait for read response, and save it
            begin
                rw_r <= 2'b0;
                if (drp_done == 1'b1)
                    begin
                        config_reg_r <= drp_data_out_r; // save configuration
                        st <= st6;
                    end
                else
                    st <= st5;
            end

        st6 : // Write new configuration
            begin
                rw_r <= 2'b10; // write
                drp_addr_r <= 7'h40;
                drp_data_in_r <= {config_reg_r[15:5], input_select_r};
                st <= st7;
            end

        st7 : // Wait to finish, then go to delay
            begin
                rw_r <= 2'b0;
                if (drp_done == 1'b1)
                    begin
                        st <= st15;
                    end
                else
                    st <= st7;
            end

        st8 : // Tell xadc to read from register
            begin
                if (busy_xadc == 1'b0)
                    begin
                        convst_r <= 1'b1; // init conversion
                        st <= st9;
                    end
                else
                    st <= st8;
            end

        st9 : // Wait for conversion to finish, then read data
            begin
                convst_r <= 1'b0;
                if (eoc == 1'b1) // data available, check to see if it is correct, then read it
                    begin
                        if (channel != input_select_r) // Hasn't switched over yet
                            st <= st8;
                        else
                            begin
                                drp_addr_r <= {2'b0, input_select_r};
                                rw_r <= 2'b01; // read
                                st <= st10;
                            end
                    end
                else
                    st <= st9;
            end

        st10 : // Wait until done, save data
            begin
                rw_r <= 2'b0;
                if (drp_done == 1'b1)
                    begin
                        result_r <= drp_data_out_r[15:4]; // save result
                        st <= st11;
                    end
                else
                    st <= st10;
            end

        st11 : // Wait until start returns to zero
            begin
                if (start == 1'b0)
                    begin
                        st <= idle;
                        done_r <= 1'b1;
                    end
                else
                    st <= st11;
            end

        st15 : // Delay state
            begin
                if (busy_xadc == 1'b0)
                    begin
                        if (cnt_delay == 6'b111111)
                            st <= st8;
                        else
                            st <= st15;
                        cnt_delay <= cnt_delay + 1'b1;
                    end
            end

    default :
        st <= idle;
    endcase
    end
end



// State machine to drive DRP transactions
always @(posedge clk125)
begin
    if (rst)
        begin
            st_drp <= idle;
            drp_done_r <= 1'b0;
        end
    else if (1'b1)
        begin
        case (st_drp)
            idle :
                begin
                    if (rw == 2'b01) // read
                        begin
                            drp_done_r <= 1'b0;
                            daddr_r <= drp_addr;
                            den_r <= 1'b1;
                            st_drp <= st1;
                        end
                    else if (rw == 2'b10) // write
                        begin
                            drp_done_r <= 1'b0;
                            daddr_r <= drp_addr;
                            den_r <= 1'b1;
                            dwe_r <= 1'b1;
                            di_r <= drp_data_in_r;
                            st_drp <= st2;
                        end
                    else
                        begin
                            drp_done_r <= 1'b0;
                            st_drp <= idle;
                        end
                end

            st1 :
                begin
                    den_r <= 1'b0;
                    if (drdy == 1'b1) // If data is ready to be read
                        begin
                            drp_data_out_r <= do_out;
                            drp_done_r <= 1'b1;
                            st_drp <= idle;
                        end
                    else
                        st_drp <= st1;
                end

            st2 :
                begin
                    den_r <= 1'b0;
                    dwe_r <= 1'b0;
                    if (drdy == 1'b1) // If write is complete
                        begin
                            drp_done_r <= 1'b1;
                            st_drp <= idle;
                        end
                    else
                        st_drp <= st2;
                end

        default :
            st_drp <= idle;
        endcase
        end
end



//ila_0 ila
//(
//    .clk(clk125),
//    .probe0(drp_data_out_r), // 16
//    .probe1(busy_xadc), // 1
//    .probe2(ch_sel), // 5
//    .probe3(result_r), // 12
//    .probe4(drdy), // 1
//    .probe5(daddr), // 7
//    .probe6(st), // 4
//    .probe7(drp_done), // 1
//    .probe8(den), // 1
//    .probe9(dwe), // 1
//    .probe10(rw), // 2
//    .probe11(di), // 16
//    .probe12(convst), // 1
//    .probe13(done), // 1
//    .probe14(start), // 1
//    .probe15(channel), // 5
//    .probe16(do_out), // 16
//    .probe17(eoc), // 1
//    .probe18(drp_addr), // 7
//    .probe19(drp_done), // 1
//    .probe20(rst_xadc) // 1
//);

endmodule
