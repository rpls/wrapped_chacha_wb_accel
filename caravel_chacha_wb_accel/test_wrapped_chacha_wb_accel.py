import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, with_timeout, Timer, First

from cocotbext.uart import UartSink

import struct

REF_OUT = [
    0x77EADF2B, 0x25D46682, 0xE6FB163B, 0x58F29AAD,
    0xAF78337D, 0xD03177EA, 0x3961148D, 0x3F4E137C,
    0xC62831CD, 0x42B01CBB, 0xB846929E, 0xED41D511,
    0xE88BE8AB, 0xAAC13170, 0x8680A967, 0xEF397287
]

async def get_output(dut):
    uart = UartSink(dut.soc_txd, 1000000)
    data = bytearray()
    while len(data) < 64:
        await uart.wait(10, 'ms')
        data.extend(await uart.read())
        # if b'\n' in data:
        #     pos = data.find('\n')
        #     print(data[0:pos+1].decode('ascii'))
        #     data = bytearray(data[pos:])
    chacha_out = struct.unpack("<" + "I"*16, data)
    print()
    for i, out in enumerate(chacha_out):
        print(f"0x{out:08X}u", end=", " if i > 4 and i % 4 else ",\n")
    assert all(ref == out for ref, out in zip(REF_OUT, chacha_out))

@cocotb.test()
async def test_start(dut):
    clock = Clock(dut.clk, 25, units="ns") # 40M
    cocotb.fork(clock.start())
    
    dut.RSTB <= 0
    dut.power1 <= 0;
    dut.power2 <= 0;
    dut.power3 <= 0;
    dut.power4 <= 0;

    await ClockCycles(dut.clk, 8)
    dut.power1 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power2 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power3 <= 1;
    await ClockCycles(dut.clk, 8)
    dut.power4 <= 1;

    await ClockCycles(dut.clk, 80)
    dut.RSTB <= 1

    # wait with a timeout for the project to become active
    await with_timeout(RisingEdge(dut.uut.mprj.wrapped_chacha_wb_accel.active), 10, 'ms')
    reader = cocotb.fork(get_output(dut))
    await with_timeout(FallingEdge(dut.uut.mprj.wrapped_chacha_wb_accel.active), 10, 'ms')
    reader.kill()
