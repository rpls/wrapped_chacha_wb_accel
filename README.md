# Wishbone ChaCha Accelerator

This is an extremely simple (technically incomplete), ChaCha20 accelerator for
the MPW2-C [multi project
submission](https://github.com/mattvenn/multi_project_tools). The accelerator is
exposed to the Wishbone bus. The state of the accelerator is simply the state of
the ChaCha Cipher (i.e., a 4x4 matrix of 32-bit integers). The Wishbone bus
exposes an interface to shift 32-bit words in or out of the state, and a status
bit to check the status and start the permutation. The last step of the
permutation, i.e. the addition of the original permutation input to the output,
is missing.

![Image of the core](docs/core.png)

# Requirements

- All the requirements for [multi project tools](https://github.com/mattvenn/multi_project_tools)
- The [cocotb](https://github.com/cocotb/cocotb) testbenches additionally require the [cocotb-bus](https://github.com/cocotb/cocotb-bus) library. They also utilize the [cocotbext-uart](https://github.com/alexforencich/cocotbext-uart) and [cocotbext-wishbone extensions](https://github.com/wallento/cocotbext-wishbone), which I have included in this repository.

# License

This project is [licensed under Apache 2](LICENSE)
