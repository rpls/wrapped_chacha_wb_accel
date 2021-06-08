/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "verilog/dv/caravel/defs.h"
#include <sys/types.h>

#ifndef USERID
#define USERID 9
#endif

static void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

static void puts(const char* s)
{
  while (*s)
		putchar(*(s++));
}

static void send_hex_bytes(const char *name, void* buf, unsigned len)
{
  const unsigned char* buf_c = buf;
	puts(name);
	putchar(':');
  for (unsigned i = 0; i < len; ++i) {
    if (i % 16 == 0) {
      putchar('\n');
    }
    int c = buf_c[i];
    int h = (c >> 4) & 0xFu;
    putchar((h < 10 ? '0' : 'A' - 10) + h);
    h = c & 0xFu;
    putchar((h < 10 ? '0' : 'A' - 10) + h);
  }
	putchar('\n');
}

static void send_bytes(void* buf, unsigned len)
{
  const unsigned char* buf_c = buf;
  for (unsigned i = 0; i < len; ++i) {
    reg_uart_data = buf_c[i];
  }
}


#define TEST_FREQ 40000000
#define TEST_BAUD 1000000

#define reg_chacha_status (*(volatile uint32_t*)0x30000000)
#define reg_chacha_key (*(volatile uint32_t*)0x30000004)
#define reg_chacha_iv (*(volatile uint32_t*)0x30000008)
#define reg_chacha_cnt (*(volatile uint32_t*)0x3000000C)
#define reg_chacha_ct (*(volatile uint32_t*)0x30000010)

void chacha_accel_config(const unsigned char key[32], const unsigned char iv[12], uint32_t counter)
{
  while((reg_chacha_status & 0x1) != 0x1);
  if (key) {
    for (int i = 0; i < 32; i+=4) {
      reg_chacha_key = key[i] | (key[i+1] << 8) | (key[i+2] << 16) | (key[i+3] << 24);
    }
  }
  if (iv) {
    for (int i = 0; i < 12; i+=4) {
      reg_chacha_iv = iv[i] | (iv[i+1] << 8) | (iv[i+2] << 16) | (iv[i+3] << 24);
    }
  }
  reg_chacha_cnt = counter;
  reg_chacha_status |= 0x1;
}

void chacha_accel_get(uint32_t* output, size_t num)
{
  for (int i = 0; i < num; i++) {
    while((reg_chacha_status & 0x1) != 0x1);
    output[i] = reg_chacha_ct;
  }
}

void main()
{
	/* Pull all low */
	reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;
	/* Shared UART pins (6 = TXD, 7 = RXD) */
	reg_mprj_io_6 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_7 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;

  reg_uart_clkdiv = (TEST_FREQ / TEST_BAUD);
  reg_uart_enable = 1;

	/* Apply configuration */
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1) {
	}

	const unsigned char key[] = {
    0x00u, 0x01u, 0x02u, 0x03u, 0x04u, 0x05u, 0x06u, 0x07u,
    0x08u, 0x09u, 0x0au, 0x0bu, 0x0cu, 0x0du, 0x0eu, 0x0fu,
    0x10u, 0x11u, 0x12u, 0x13u, 0x14u, 0x15u, 0x16u, 0x17u,
    0x18u, 0x19u, 0x1au, 0x1bu, 0x1cu, 0x1du, 0x1eu, 0x1fu,
  };

  const unsigned char iv[] = {
    0x00u, 0x00u, 0x00u, 0x00u,
    0x00u, 0x01u, 0x02u, 0x03u,
    0x04u, 0x05u, 0x06u, 0x07u,
  };

	// activate the project by setting the 1st bit of 2nd bank of LA - depends on the project ID
	reg_la1_iena = 0; // input enable off
	reg_la1_oenb = 0; // output enable on
	reg_la1_data = 1 << USERID;

	reg_la0_iena = 1;
	reg_la0_oenb = 1;
  while (reg_la0_data & 0x1 != 1);

  chacha_accel_config(key, iv, 0);
  for (int i = 0; i < 4; ++i) {
    uint32_t data[16];
    chacha_accel_get(data, 16);
    send_bytes(data, sizeof(data));
  }

	// activate the project by setting the 1st bit of 2nd bank of LA - depends on the project ID
	reg_la1_iena = 0; // input enable off
	reg_la1_oenb = 0; // output enable on
	reg_la1_data = 0 << USERID;
}
