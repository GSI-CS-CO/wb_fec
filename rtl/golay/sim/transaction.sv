class transaction;
 
  //declaring the transaction items
  rand bit [11:0] payload;
       bit [11:0] codeword;
       bit [23:0] codepay;

  function void display(string name, bit [11:00] code);
    $display("-------------------------");
    $display("- %s ",name);
    $display("-------------------------");
    $display("- payload = %x ",payload);
    $display("- codeword = %x ",code);
  endfunction
   
endclass
