// Generator : SpinalHDL v1.4.3    git head : adf552d8f500e7419fff395b7049228e4bc5de26
// Component : chacha_wb_accel
// Git hash  : 0b00313db640c318d10a80ad1464662703d3ca52

`timescale 1ns/1ps 
`define fsm_enumDefinition_binary_sequential_type [2:0]
`define fsm_enumDefinition_binary_sequential_fsm_BOOT 3'b000
`define fsm_enumDefinition_binary_sequential_fsm_CYCLE 3'b001
`define fsm_enumDefinition_binary_sequential_fsm_PERMUTE 3'b010
`define fsm_enumDefinition_binary_sequential_fsm_TOODD 3'b011
`define fsm_enumDefinition_binary_sequential_fsm_TOEVEN 3'b100


module chacha_wb_accel (
  input               wb_CYC,
  input               wb_STB,
  output              wb_ACK,
  input               wb_WE,
  input      [3:0]    wb_ADR,
  output reg [31:0]   wb_DAT_MISO,
  input      [31:0]   wb_DAT_MOSI,
  output              interrupt,
  input               clk,
  input               reset
);
  wire       [31:0]   _zz_2;
  reg                 _zz_3;
  reg                 _zz_4;
  wire       [31:0]   accel_io_state_out;
  wire                accel_io_ready;
  wire       [0:0]    _zz_5;
  wire       [0:0]    _zz_6;
  wire       [0:0]    _zz_7;
  wire                slaveFactory_askWrite;
  wire                slaveFactory_askRead;
  wire                slaveFactory_doWrite;
  wire                slaveFactory_doRead;
  reg                 _zz_1;
  wire       [5:0]    slaveFactory_byteAddress;
  reg                 bridge_interruptEnable;
  reg                 bridge_interruptPending;
  reg                 bridge_busy;
  reg                 accel_io_ready_regNext;
  wire                bridge_gettingReady;
  reg                 accel_io_ready_regNext_1;

  assign _zz_5 = wb_DAT_MOSI[0 : 0];
  assign _zz_6 = wb_DAT_MOSI[1 : 1];
  assign _zz_7 = wb_DAT_MOSI[2 : 2];
  ChaChaRegBased accel (
    .io_state_in     (_zz_2[31:0]               ), //i
    .io_state_out    (accel_io_state_out[31:0]  ), //o
    .io_cycle        (_zz_3                     ), //i
    .io_start        (_zz_4                     ), //i
    .io_ready        (accel_io_ready            ), //o
    .clk             (clk                       ), //i
    .reset           (reset                     )  //i
  );
  always @ (*) begin
    wb_DAT_MISO = 32'h0;
    case(slaveFactory_byteAddress)
      6'h0 : begin
        wb_DAT_MISO[0 : 0] = accel_io_ready;
        wb_DAT_MISO[1 : 1] = bridge_interruptPending;
        wb_DAT_MISO[2 : 2] = bridge_interruptEnable;
      end
      6'h04 : begin
        wb_DAT_MISO[31 : 0] = accel_io_state_out;
      end
      default : begin
      end
    endcase
  end

  assign slaveFactory_askWrite = ((wb_CYC && wb_STB) && wb_WE);
  assign slaveFactory_askRead = ((wb_CYC && wb_STB) && (! wb_WE));
  assign slaveFactory_doWrite = (((wb_CYC && wb_STB) && ((wb_CYC && wb_ACK) && wb_STB)) && wb_WE);
  assign slaveFactory_doRead = (((wb_CYC && wb_STB) && ((wb_CYC && wb_ACK) && wb_STB)) && (! wb_WE));
  assign wb_ACK = (_zz_1 && wb_STB);
  assign slaveFactory_byteAddress = ({2'd0,wb_ADR} <<< 2);
  assign bridge_gettingReady = (accel_io_ready && (! accel_io_ready_regNext));
  always @ (*) begin
    _zz_4 = 1'b0;
    case(slaveFactory_byteAddress)
      6'h0 : begin
        if(slaveFactory_doWrite)begin
          _zz_4 = _zz_5[0];
        end
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    _zz_3 = 1'b0;
    case(slaveFactory_byteAddress)
      6'h04 : begin
        if(slaveFactory_doWrite)begin
          _zz_3 = 1'b1;
        end
        if(slaveFactory_doRead)begin
          _zz_3 = 1'b1;
        end
      end
      default : begin
      end
    endcase
  end

  assign interrupt = bridge_interruptPending;
  assign _zz_2 = wb_DAT_MOSI[31 : 0];
  always @ (posedge clk) begin
    if(reset) begin
      _zz_1 <= 1'b0;
      bridge_interruptEnable <= 1'b0;
      bridge_interruptPending <= 1'b0;
      bridge_busy <= 1'b0;
      accel_io_ready_regNext <= 1'b0;
      accel_io_ready_regNext_1 <= 1'b0;
    end else begin
      _zz_1 <= (wb_STB && wb_CYC);
      accel_io_ready_regNext <= accel_io_ready;
      if(((bridge_gettingReady && bridge_busy) && bridge_interruptEnable))begin
        bridge_interruptPending <= 1'b1;
      end
      accel_io_ready_regNext_1 <= accel_io_ready;
      if(((! accel_io_ready) && accel_io_ready_regNext_1))begin
        bridge_busy <= 1'b1;
      end
      if(bridge_gettingReady)begin
        bridge_busy <= 1'b0;
      end
      case(slaveFactory_byteAddress)
        6'h0 : begin
          if(slaveFactory_doWrite)begin
            bridge_interruptPending <= _zz_6[0];
            bridge_interruptEnable <= _zz_7[0];
          end
          if(slaveFactory_doRead)begin
            bridge_interruptPending <= 1'b0;
          end
        end
        default : begin
        end
      endcase
    end
  end


  initial begin
    $dumpfile("chacha_wb_accel.fst");
    $dumpvars(0, chacha_wb_accel);
  end

endmodule

module ChaChaRegBased (
  input      [31:0]   io_state_in,
  output     [31:0]   io_state_out,
  input               io_cycle,
  input               io_start,
  output reg          io_ready,
  input               clk,
  input               reset
);
  wire       [0:0]    _zz_3;
  wire       [8:0]    _zz_4;
  reg        [31:0]   state_0;
  reg        [31:0]   state_1;
  reg        [31:0]   state_2;
  reg        [31:0]   state_3;
  reg        [31:0]   state_4;
  reg        [31:0]   state_5;
  reg        [31:0]   state_6;
  reg        [31:0]   state_7;
  reg        [31:0]   state_8;
  reg        [31:0]   state_9;
  reg        [31:0]   state_10;
  reg        [31:0]   state_11;
  reg        [31:0]   state_12;
  reg        [31:0]   state_13;
  reg        [31:0]   state_14;
  reg        [31:0]   state_15;
  reg        [31:0]   nextState_0;
  reg        [31:0]   nextState_1;
  reg        [31:0]   nextState_2;
  reg        [31:0]   nextState_3;
  reg        [31:0]   nextState_4;
  reg        [31:0]   nextState_5;
  reg        [31:0]   nextState_6;
  reg        [31:0]   nextState_7;
  reg        [31:0]   nextState_8;
  reg        [31:0]   nextState_9;
  reg        [31:0]   nextState_10;
  reg        [31:0]   nextState_11;
  reg        [31:0]   nextState_12;
  reg        [31:0]   nextState_13;
  reg        [31:0]   nextState_14;
  reg        [31:0]   nextState_15;
  reg                 counter_willIncrement;
  wire                counter_willClear;
  reg        [8:0]    counter_valueNext;
  reg        [8:0]    counter_value;
  wire                counter_willOverflowIfInc;
  wire                counter_willOverflow;
  wire       [31:0]   permutation_a;
  wire       [31:0]   permutation_b;
  wire       [31:0]   permutation_c;
  wire       [31:0]   permutation_d;
  wire       [1:0]    permutation_rot;
  wire       [31:0]   permutation_na;
  wire       [31:0]   permutation_nb;
  wire       [31:0]   permutation_nc;
  wire       [31:0]   permutation_nd;
  wire       [31:0]   _zz_1;
  reg        [31:0]   _zz_2;
  wire       [4:0]    round;
  wire                odd;
  wire       [3:0]    permuteCnt;
  wire       [3:0]    lastPermute;
  wire                fsm_wantExit;
  reg                 fsm_wantStart;
  reg        `fsm_enumDefinition_binary_sequential_type fsm_stateReg;
  reg        `fsm_enumDefinition_binary_sequential_type fsm_stateNext;
  `ifndef SYNTHESIS
  reg [87:0] fsm_stateReg_string;
  reg [87:0] fsm_stateNext_string;
  `endif


  assign _zz_3 = counter_willIncrement;
  assign _zz_4 = {8'd0, _zz_3};
  `ifndef SYNTHESIS
  always @(*) begin
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_BOOT : fsm_stateReg_string = "fsm_BOOT   ";
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : fsm_stateReg_string = "fsm_CYCLE  ";
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : fsm_stateReg_string = "fsm_PERMUTE";
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : fsm_stateReg_string = "fsm_TOODD  ";
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : fsm_stateReg_string = "fsm_TOEVEN ";
      default : fsm_stateReg_string = "???????????";
    endcase
  end
  always @(*) begin
    case(fsm_stateNext)
      `fsm_enumDefinition_binary_sequential_fsm_BOOT : fsm_stateNext_string = "fsm_BOOT   ";
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : fsm_stateNext_string = "fsm_CYCLE  ";
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : fsm_stateNext_string = "fsm_PERMUTE";
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : fsm_stateNext_string = "fsm_TOODD  ";
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : fsm_stateNext_string = "fsm_TOEVEN ";
      default : fsm_stateNext_string = "???????????";
    endcase
  end
  `endif

  always @ (*) begin
    nextState_0 = state_0;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_0 = state_1;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_0 = state_1;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_1 = state_1;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_1 = state_2;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_1 = state_2;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_2 = state_2;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_2 = state_3;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_2 = state_3;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_3 = state_3;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_3 = state_4;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_3 = permutation_na;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_4 = state_4;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_4 = state_5;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_4 = state_5;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_4 = state_5;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_4 = state_7;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_5 = state_5;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_5 = state_6;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_5 = state_6;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_5 = state_6;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_5 = state_4;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_6 = state_6;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_6 = state_7;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_6 = state_7;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_6 = state_7;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_6 = state_5;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_7 = state_7;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_7 = state_8;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_7 = permutation_nb;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_7 = state_4;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_7 = state_6;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_8 = state_8;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_8 = state_9;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_8 = state_9;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_8 = state_10;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_8 = state_10;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_9 = state_9;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_9 = state_10;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_9 = state_10;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_9 = state_11;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_9 = state_11;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_10 = state_10;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_10 = state_11;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_10 = state_11;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_10 = state_8;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_10 = state_8;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_11 = state_11;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_11 = state_12;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_11 = permutation_nc;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_11 = state_9;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_11 = state_9;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_12 = state_12;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_12 = state_13;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_12 = state_13;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_12 = state_15;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_12 = state_13;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_13 = state_13;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_13 = state_14;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_13 = state_14;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_13 = state_12;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_13 = state_14;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_14 = state_14;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_14 = state_15;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_14 = state_15;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_14 = state_13;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_14 = state_15;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    nextState_15 = state_15;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_cycle)begin
          nextState_15 = io_state_in;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        nextState_15 = permutation_nd;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        nextState_15 = state_14;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        nextState_15 = state_12;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    counter_willIncrement = 1'b0;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        counter_willIncrement = 1'b1;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  assign counter_willClear = 1'b0;
  assign counter_willOverflowIfInc = (counter_value == 9'h13f);
  assign counter_willOverflow = (counter_willOverflowIfInc && counter_willIncrement);
  always @ (*) begin
    if(counter_willOverflow)begin
      counter_valueNext = 9'h0;
    end else begin
      counter_valueNext = (counter_value + _zz_4);
    end
    if(counter_willClear)begin
      counter_valueNext = 9'h0;
    end
  end

  assign permutation_nc = (permutation_a + permutation_b);
  assign permutation_nd = permutation_b;
  assign permutation_na = permutation_c;
  assign _zz_1 = (permutation_nc ^ permutation_d);
  always @ (*) begin
    case(permutation_rot)
      2'b00 : begin
        _zz_2 = {_zz_1[15 : 0],_zz_1[31 : 16]};
      end
      2'b01 : begin
        _zz_2 = {_zz_1[19 : 0],_zz_1[31 : 20]};
      end
      2'b10 : begin
        _zz_2 = {_zz_1[23 : 0],_zz_1[31 : 24]};
      end
      default : begin
        _zz_2 = {_zz_1[24 : 0],_zz_1[31 : 25]};
      end
    endcase
  end

  assign permutation_nb = _zz_2;
  assign permutation_a = state_0;
  assign permutation_b = state_4;
  assign permutation_c = state_8;
  assign permutation_d = state_12;
  assign permutation_rot = counter_value[3 : 2];
  assign round = counter_value[8 : 4];
  assign odd = round[0];
  assign permuteCnt = counter_value[3 : 0];
  assign lastPermute = 4'b1111;
  assign io_state_out = state_0;
  always @ (*) begin
    io_ready = 1'b0;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        io_ready = 1'b1;
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
      end
    endcase
  end

  assign fsm_wantExit = 1'b0;
  always @ (*) begin
    fsm_wantStart = 1'b0;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
      end
      default : begin
        fsm_wantStart = 1'b1;
      end
    endcase
  end

  always @ (*) begin
    fsm_stateNext = fsm_stateReg;
    case(fsm_stateReg)
      `fsm_enumDefinition_binary_sequential_fsm_CYCLE : begin
        if(io_start)begin
          fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_PERMUTE;
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_PERMUTE : begin
        if((permuteCnt == lastPermute))begin
          if(odd)begin
            fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_TOEVEN;
          end else begin
            fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_TOODD;
          end
        end
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOODD : begin
        fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_PERMUTE;
      end
      `fsm_enumDefinition_binary_sequential_fsm_TOEVEN : begin
        if((counter_value == 9'h0))begin
          fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_CYCLE;
        end else begin
          fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_PERMUTE;
        end
      end
      default : begin
      end
    endcase
    if(fsm_wantStart)begin
      fsm_stateNext = `fsm_enumDefinition_binary_sequential_fsm_CYCLE;
    end
  end

  always @ (posedge clk) begin
    if(reset) begin
      state_0 <= 32'h0;
      state_1 <= 32'h0;
      state_2 <= 32'h0;
      state_3 <= 32'h0;
      state_4 <= 32'h0;
      state_5 <= 32'h0;
      state_6 <= 32'h0;
      state_7 <= 32'h0;
      state_8 <= 32'h0;
      state_9 <= 32'h0;
      state_10 <= 32'h0;
      state_11 <= 32'h0;
      state_12 <= 32'h0;
      state_13 <= 32'h0;
      state_14 <= 32'h0;
      state_15 <= 32'h0;
      counter_value <= 9'h0;
      fsm_stateReg <= `fsm_enumDefinition_binary_sequential_fsm_BOOT;
    end else begin
      state_0 <= nextState_0;
      state_1 <= nextState_1;
      state_2 <= nextState_2;
      state_3 <= nextState_3;
      state_4 <= nextState_4;
      state_5 <= nextState_5;
      state_6 <= nextState_6;
      state_7 <= nextState_7;
      state_8 <= nextState_8;
      state_9 <= nextState_9;
      state_10 <= nextState_10;
      state_11 <= nextState_11;
      state_12 <= nextState_12;
      state_13 <= nextState_13;
      state_14 <= nextState_14;
      state_15 <= nextState_15;
      counter_value <= counter_valueNext;
      fsm_stateReg <= fsm_stateNext;
    end
  end


endmodule
