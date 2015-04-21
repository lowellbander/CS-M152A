`timescale 1ns / 1ps

module model_uart(/*AUTOARG*/
   // Outputs
   TX,
   // Inputs
   RX
   );

   output TX;
   input  RX;

   parameter baud    = 115200;
   parameter bittime = 1000000000/baud;
   parameter name    = "UART0";
   
   reg [7:0] rxData;
   event     evBit;
   event     evByte;
   event     evTxBit;
   event     evTxByte;
   reg       TX;
   
   reg [47:0] buff;
   
   reg [2:0] buff_cnt;

   initial
     begin
        TX = 1'b1;
        buff_cnt = 2'b00;
        buff = 0;
     end
   
   always @ (negedge RX)
     begin
        rxData[7:0] = 8'h0;
        #(0.5*bittime);
        repeat (8)
          begin
             #bittime ->evBit;
             //rxData[7:0] = {rxData[6:0],RX};
             rxData[7:0] = {RX,rxData[7:1]};
          end
         ->evByte;

        buff[47:0] <= {buff[39:0], rxData[7:0]};
        buff_cnt <= buff_cnt + 1;
        
        if (buff_cnt[2] & buff_cnt[0])
        begin
            buff_cnt <= 0;
        end
        
        if (buff_cnt[2] & buff_cnt[0])
        begin
            $display ("%d %s Received bytes:(%s%s%s%s)", $stime, name, 
                  buff[39:32], buff[31:24], buff[23:16], buff[15:8]);
        end

//        $display ("%d %s Received byte %02x (%s)", $stime, name, rxData, rxData);
     end

   task tskRxData;
      output [7:0] data;
      begin
         @(evByte);
         data = rxData;
      end
   endtask // for
      
   task tskTxData;
      input [7:0] data;
      reg [9:0]   tmp;
      integer     i;
      begin
         tmp = {1'b1, data[7:0], 1'b0};
         for (i=0;i<10;i=i+1)
           begin
              TX = tmp[i];
              #bittime;
              ->evTxBit;
           end
         ->evTxByte;
      end
   endtask // tskTxData
   
endmodule // model_uart
