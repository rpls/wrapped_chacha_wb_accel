import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, with_timeout, Timer, First

from cocotbext.uart import UartSink

import struct

REF_OUTPUT = bytes.fromhex(
    r"""
f798a189f195e66982105ffb640bb7757f579da31602fc93ec01ac56
f85ac3c134a4547b733b46413042c9440049176905d3be59ea1c53f1
5916155c2be8241a38008b9a26bc35941e2444177c8ade6689de9526
4986d95889fb60e84629c9bd9a5acb1cc118be563eb9b3a4a472f82e
09a7e778492b562ef7130e88dfe031c79db9d4f7c7a899151b9a4750
32b63fc385245fe054e3dd5a97a5f576fe064025d3ce042c566ab2c5
07b138db853e3d6959660996546cc9c4a6eafdc777c040d70eaf46f7
6dad3979e5c5360c3317166a1c894c94a371876a94df7628fe4eaaf2
ccb27d5aaae0ad7ad0f9d4b6ad3b54098746d4524d38407a6deb3ab7
8fab78c9"""
)

async def get_output(dut):
    uart = UartSink(dut.soc_txd, 1000000)
    data = bytearray()
    while len(data) < len(REF_OUTPUT):
        await uart.wait(10, 'ms')
        data.extend(await uart.read())
    for i, out in enumerate(data):
        print(f"0x{out:02X}u", end=", " if i > 1 and i % 16 else ",\n")
    assert all(ref == out for ref, out in zip(REF_OUTPUT, data))

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
    await with_timeout(RisingEdge(dut.uut.mprj.wrapped_chacha_wb_accel_9.active), 10, 'ms')
    reader = cocotb.fork(get_output(dut))
    await with_timeout(FallingEdge(dut.uut.mprj.wrapped_chacha_wb_accel_9.active), 10, 'ms')
    reader.kill()
