import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, ReadWrite, with_timeout
from cocotbext.wishbone.driver import WishboneMaster, WBOp, WBRes

import random
import struct

import pprint

W = 32
M = 2 ** 32 - 1

def rot(a, r):
    return ((a << r) & M) | ((a >> (W - r)) & M)


def qr(a, b, c, d):
    a = (a + b) & M
    d ^= a
    d = rot(d, 16)
    c = (c + d) & M
    b ^= c
    b = rot(b, 12)
    a = (a + b) & M
    d ^= a
    d = rot(d, 8)
    c = (c + d) & M
    b ^= c
    b = rot(b, 7)
    return (a, b, c, d)


def chacha20(s):
    s = s.copy()
    for r in range(10):
        for i in range(4):
            s[i::4] = qr(*s[i::4])
        s[0], s[5], s[10], s[15] = qr(s[0], s[5], s[10], s[15])
        s[1], s[6], s[11], s[12] = qr(s[1], s[6], s[11], s[12])
        s[2], s[7], s[8], s[13] = qr(s[2], s[7], s[8], s[13])
        s[3], s[4], s[9], s[14] = qr(s[3], s[4], s[9], s[14])
    return s


async def reset(dut):
    dut.reset <= 1
    await ClockCycles(dut.clk, 5)
    dut.reset <= 0
    await ClockCycles(dut.clk, 20)


async def test_permutation(dut, wbs):
    chacha_in = [random.getrandbits(32) for i in range(16)]
    chacha_out_ref = chacha20(chacha_in)
    status, = await wbs.send_cycle([WBOp(adr=0)])
    interruptEnabled = status.datrd.value & 0x4
    # Shift in the state
    await wbs.send_cycle([WBOp(adr=1, dat=d) for d in chacha_in])
    # Start the accelerator
    await wbs.send_cycle([WBOp(adr=0, dat=0x1 | interruptEnabled)])
    if interruptEnabled:
        await with_timeout(RisingEdge(dut.interrupt), 100, 'us')
        # Check if interrupt pending flag is set
        res, = await wbs.send_cycle([WBOp(adr=0)])
        assert (res.datrd.value & 0x2) == 0x2
        # Check if interrupt pending flag was cleared
        res, = await wbs.send_cycle([WBOp(adr=0)])
        assert (res.datrd.value & 0x2) == 0x0
        pass
    else:
        # Wait until not busy anymore
        t = 0
        status, = await wbs.send_cycle([WBOp(adr=0)])
        while int(status.datrd) != 1:
            if t % 100 == 0:
                print(f"Status byte is {status.datrd}")
            status, = await wbs.send_cycle([WBOp(adr=0)])
            t += 1
            assert t < 5000
    # Read out result
    rsp = await wbs.send_cycle([WBOp(adr=1) for d in chacha_in])
    rsp = [int(r.datrd) for r in rsp]
    assert all(ref == res for ref, res in zip(chacha_out_ref, rsp))


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
    wbs = WishboneMaster(dut, "wb", dut.clk,
                         width=32,
                         timeout=10,
                         signals_dict={
                             "cyc":  "CYC",
                             "stb":  "STB",
                             "we":   "WE",
                             "adr":  "ADR",
                             "datwr":"DAT_MOSI",
                             "datrd":"DAT_MISO",
                             "ack":  "ACK"
                         })
    await test_permutation(dut, wbs)
    # Check if interrupts are enabled
    res, = await wbs.send_cycle([WBOp(adr=0)])
    assert res.datrd.value & 0x4 == 0x0
    res, = await wbs.send_cycle([WBOp(adr=0, dat=0x4)])
    # Enable interrupts
    res, = await wbs.send_cycle([WBOp(adr=0)])
    assert res.datrd.value & 0x4 == 0x4
    await test_permutation(dut, wbs)
