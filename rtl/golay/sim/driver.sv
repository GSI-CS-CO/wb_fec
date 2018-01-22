class driver;
  
  //used to count the number of transactions
  int no_transactions;
  int fails;
  int positive_fails;
  int ok;
   
  //creating virtual interface handle
  virtual intf vif;
   
  //creating mailbox handle
  mailbox gen2driv;
    
  bit[11 : 0] tmp;

  //random
  integer num_err, err_pos;
   
  //constructor
  function new(virtual intf vif,mailbox gen2driv);
    //getting the interface
    this.vif = vif;
    //getting the mailbox handles from  environment
    this.gen2driv = gen2driv;
  endfunction
   
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(vif.reset);
    $display("[ DRIVER ] ----- Reset Started -----");
    vif.payload <= '0;
    vif.stb     <= 0;
    vif.stb_dec <= 0;
    wait(vif.reset);
    $display("[ DRIVER ] ----- Reset Ended   -----");
  endtask
  
  //drivers the transaction items to interface signals
  task main;
    forever begin
      transaction trans;
      gen2driv.get(trans);
      @(posedge vif.clk);
      vif.stb       <= 1;
      vif.payload   <= trans.payload;
      @(posedge vif.clk);
      vif.stb       <= 0;
      trans.display("[ Driver ]",vif.codeword);
      vif.codepay    <= {trans.payload,vif.codeword};
      @(posedge vif.clk);
      //num_err = $urandom_range(6,0);
      num_err = 3;
      $display("[ ERROR ] Num : %d", num_err);
      for (int i = 0; i < num_err; i++) begin
        err_pos = $urandom_range(23,0);
        vif.codepay = vif.codepay ^ ('h1 << err_pos);
        $display("[ ERROR ] Pos : %d", err_pos);
      end
      $display("[ RX CODEWORD ] %h", vif.codepay);
      vif.stb_dec    <= 1;
      @(posedge vif.clk);
      vif.stb_dec    <= 0;
      wait(vif.decoded | vif.failed);
      $display("[ DEC CODEWORD ] %h", vif.payload_rec);
      
      if ((vif.payload_rec == trans.payload) & vif.decoded == 1)
          begin
          ok++;
        $display("-----DECODED-----");
      end

      if ((vif.payload_rec != trans.payload) & vif.failed == 1)
          begin
          fails++;
        $display("-----FAILED-----");
      end
      if ((vif.payload_rec != trans.payload) & vif.decoded == 1)
          begin
          positive_fails++;
          $display("-----WRONG DECODED-----");
      end
      $display("-------------------------");
      @(posedge vif.clk);
      no_transactions++;
    end
  endtask
endclass
