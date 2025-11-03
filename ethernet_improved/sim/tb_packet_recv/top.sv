`timescale 1ns/1ps
import tran_cls::*;
module top;

    Input_tran transaction, copy_of_transaction;
    Result_tran result, copy_of_result;
    string s;

    initial begin
        transaction = new(
            48'hFF_FF_FF_FF_FF_FF,
            48'hFF_FF_FF_FF_FF_FF,
            16'h00_0A,
            10
        );
        copy_of_transaction = transaction.clone();

        s = $sformatf("%s", transaction.convert2string());
        $display("%s", s);
        $display("Clone:");
        s = $sformatf("%s", copy_of_transaction.convert2string());
        $display("%s", s);

        result = new(112'hFFFFFFFFFFFFFFFFFFFFFFFF000A);
        result.add_word(8'hFE);
        result.add_word(8'hED);
        result.add_word(8'hBE);
        result.add_word(8'hEF);
        s = $sformatf("%s", result.convert2string());
        $display("Result:");
        $display("%s", s);
        copy_of_result = result.clone();
        s = $sformatf("%s", copy_of_result.convert2string());
        $display("Copy of Result:");
        $display("%s", s);
        $finish;
    end
endmodule