import cocotb
from cocotb.clock import Clock
from cocotb.triggers import (
    RisingEdge,
    FallingEdge,
    ClockCycles,
    ReadWrite,
    with_timeout,
)
from cocotbext.wishbone.driver import WishboneMaster, WBOp, WBRes

import struct

REF_KEY = bytes.fromhex(
    r"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
)
REF_IV = bytes.fromhex(r"000000000001020304050607")
REF_COUNTER = bytes.fromhex(r"00000000")
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


async def reset(dut):
    dut.reset <= 1
    await ClockCycles(dut.clk, 5)
    dut.reset <= 0
    await ClockCycles(dut.clk, 20)


async def test_accel(dut, wbs, readblock=False):
    key = struct.unpack("<" + "I"*8, REF_KEY)
    iv = struct.unpack("<" + "I"*3, REF_IV)
    cnt = struct.unpack("<" + "I"*1, REF_COUNTER)
    ref_out = struct.unpack("<" + "I"*(len(REF_OUTPUT) // 4), REF_OUTPUT)
    (status,) = await wbs.send_cycle([WBOp(adr=0)])
    interruptEnabled = status.datrd.value & 0x4
    while status.datrd.value & 0x1 != 0x1:
        (status,) = await wbs.send_cycle([WBOp(adr=0)])
    # Cycle in the key
    await wbs.send_cycle([WBOp(adr=1, dat=k) for k in key])
    # Cycle in the iv
    await wbs.send_cycle([WBOp(adr=2, dat=i) for i in iv])
    # Cycle in the counter
    await wbs.send_cycle([WBOp(adr=3, dat=c) for c in cnt])
    # Start the accelerator
    await wbs.send_cycle([WBOp(adr=0, dat=0x1 | interruptEnabled)])
    if interruptEnabled:
        await with_timeout(RisingEdge(dut.interrupt), 100, "us")
        # Check if interrupt pending flag is set
        (res,) = await wbs.send_cycle([WBOp(adr=0)])
        assert (res.datrd.value & 0x2) == 0x2
        # Check if interrupt pending flag was cleared
        (res,) = await wbs.send_cycle([WBOp(adr=0)])
        assert (res.datrd.value & 0x2) == 0x0
    elif not readblock:
        # Wait until not busy anymore
        t = 0
        (status,) = await wbs.send_cycle([WBOp(adr=0)])
        while int(status.datrd) & 0x1 != 0x1:
            if t % 10 == 0:
                print(f"Status byte is {int(status.datrd):X}")
            (status,) = await wbs.send_cycle([WBOp(adr=0)])
            t += 1
            assert t < 5000
    else:
        print("Reading directly")
    # Read out result
    rsp = await wbs.send_cycle([WBOp(adr=4) for o in ref_out])
    rsp = [int(r.datrd) for r in rsp]
    assert all(ref == res for ref, res in zip(ref_out, rsp))


@cocotb.test()
async def test_wb_accel(dut):
    if hasattr(dut, "VPWR"):
        dut.VPWR <= 1
        dut.VGND <= 0
    if hasattr(dut, "div_valid"):
        dut.div_valid <= 0
        dut.div_payload <= 0
    clock = Clock(dut.clk, 50, units="ns")
    clkEdge = RisingEdge(dut.clk)
    cocotb.fork(clock.start())
    await reset(dut)
    wbs = WishboneMaster(
        dut,
        "wb",
        dut.clk,
        width=32,
        timeout=10,
        signals_dict={
            "cyc": "CYC",
            "stb": "STB",
            "we": "WE",
            "adr": "ADR",
            "datwr": "DAT_MOSI",
            "datrd": "DAT_MISO",
            "ack": "ACK",
        },
    )
    await test_accel(dut, wbs)
    await test_accel(dut, wbs, True)
    # Check if interrupts are enabled
    (res,) = await wbs.send_cycle([WBOp(adr=0)])
    assert res.datrd.value & 0x4 == 0x0
    (res,) = await wbs.send_cycle([WBOp(adr=0, dat=0x4)])
    # Enable interrupts
    (res,) = await wbs.send_cycle([WBOp(adr=0)])
    assert res.datrd.value & 0x4 == 0x4
    await test_accel(dut, wbs)
