// #################################################################################################
// #  < Custom Functions Unit Test Program >                                                       #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2020, Stephan Nolting. All rights reserved.                                     #
// #                                                                                               #
// # Redistribution and use in source and binary forms, with or without modification, are          #
// # permitted provided that the following conditions are met:                                     #
// #                                                                                               #
// # 1. Redistributions of source code must retain the above copyright notice, this list of        #
// #    conditions and the following disclaimer.                                                   #
// #                                                                                               #
// # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
// #    conditions and the following disclaimer in the documentation and/or other materials        #
// #    provided with the distribution.                                                            #
// #                                                                                               #
// # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
// #    endorse or promote products derived from this software without specific prior written      #
// #    permission.                                                                                #
// #                                                                                               #
// # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
// # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
// # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
// # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
// # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
// # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
// # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
// # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
// # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
// # ********************************************************************************************* #
// # The NEO430 Processor - https://github.com/stnolting/neo430                                    #
// #################################################################################################


// Libraries
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <neo430.h>

// Configuration
#define BAUD_RATE 19200

void print_all_regs(void) {

  neo430_uart_br_print("CFU_REG0 ");
  neo430_uart_print_hex_word(CFU_REG0);

  neo430_uart_br_print("\nCFU_REG1 ");
  neo430_uart_print_hex_word(CFU_REG1);

  neo430_uart_br_print("\nCFU_REG2 ");
  neo430_uart_print_hex_word(CFU_REG2);

  neo430_uart_br_print("\nCFU_REG3 ");
  neo430_uart_print_hex_word(CFU_REG3);

  neo430_uart_br_print("\nCFU_REG4 ");
  neo430_uart_print_hex_word(CFU_REG4);

  neo430_uart_br_print("\nCFU_REG5 ");
  neo430_uart_print_hex_word(CFU_REG5);

  neo430_uart_br_print("\nCFU_REG6 ");
  neo430_uart_print_hex_word(CFU_REG6);

  neo430_uart_br_print("\nCFU_REG7 ");
  neo430_uart_print_hex_word(CFU_REG7);


  neo430_uart_br_print("\n");
}

void cfu_reset()
{
	CFU_REG0 = CFU_REG0  |  (1 << 14);
	CFU_REG0 = CFU_REG0  & ~(1 << 14);
}

void md5_select()
{
	CFU_REG0 = 0x8001;
}

void cfu_enable()
{
	CFU_REG0 = CFU_REG0 | (1 << 13);
}

void cfu_disable()
{
	CFU_REG0 = CFU_REG0 & ~(1 << 13);
}

void md5_write_enable()
{
	CFU_REG0 = CFU_REG0 | (1 << 12);
}

void md5_write_disable()
{
	CFU_REG0 = CFU_REG0 & ~(1 << 12);
}


struct md5_ctx {
	uint32_t byte_count;
	uint32_t blocks_sent;
};

void md5_init(struct md5_ctx *ctx)
{
	md5_select();
	cfu_reset();
	cfu_enable();
	ctx->byte_count = 0;
	ctx->blocks_sent = 0;
}

#define MD5_ADDR_BLOCK0  (uint8_t) 0x20
#define MD5_ADDR_BLOCK15 (uint8_t) 0x2f
#define MD5_ADDR_STATUS  (uint8_t) 0x09
#define MD5_ADDR_CTRL    (uint8_t) 0x08



void md5_update(struct md5_ctx *ctx, uint8_t data[64], uint32_t len)
{
	ctx->byte_count += len;

	uint16_t reg2 = 0;
	uint16_t reg3 = 0;
	uint16_t i, j;
	uint32_t newlen = len + 1;


	if (len < 512 / 8) {

		for(; newlen % (512/8) != 448/8; newlen++);

		for (i = len + 1; i < 64; i++)
			data[i] = 0;

		// Append 1 bit
		data[len] = 0x80;

		// originally the len appended should be bitlength of data mod 2^64
		// as am i lazy to do it for 64, then just 32 will suffice, cause
		// intended use case wont be using more than 440 bit msg data.
		// So for now only allowed byte length of  message strings is less or
		// equal to 440 bits. Which is about 55 ascii characters, and sufficient
		// for possibly hashing stuff and having valid hashes

		uint32_t bits = len * 8;
		data[newlen] = (uint8_t)  bits;
		data[newlen+1] = (uint8_t) (bits >> 8);
		data[newlen+2] = (uint8_t) (bits >> 16);
		data[newlen+3] = (uint8_t) (bits >> 24);
	}


	for (i = 0, j=0; i < 512/8; i += 4, j++) {
		reg3 = (data[i+1] << 8) | (data[i]);
		reg2 = (data[i+3] << 8) | (data[i+2]);

		CFU_REG1 = MD5_ADDR_BLOCK0 + j;
		CFU_REG2 = reg2;
		CFU_REG3 = reg3;
		md5_write_enable();
		md5_write_disable();
	}

	// Block till core ready
	CFU_REG1 = MD5_ADDR_STATUS;
	while(1) {
		if (CFU_REG5 == 1) break;
	}

	CFU_REG1 = MD5_ADDR_CTRL;

	if (ctx->blocks_sent == 0) {
		CFU_REG2 = 0;
		CFU_REG3 = 1;
		md5_write_enable();
		md5_write_disable();
	}

	CFU_REG2 = 0;
	CFU_REG3 = 2;

	md5_write_enable();
	md5_write_disable();
}

#define MD5_ADDR_DIGEST0 (uint8_t) 0x40
#define MD5_ADDR_DIGEST3 (uint8_t) 0x43

void md5_finalize(struct md5_ctx *ctx, uint16_t md[8])
{

	// Block till core ready
	CFU_REG1 = MD5_ADDR_STATUS;
	while(1)
		if (CFU_REG5 == 1) break;

	uint8_t i, j;

	for(i=0, j=0; i < 4; i++, j = j+2) {
	   CFU_REG1 = MD5_ADDR_DIGEST0 + i;
	   md[j]    = CFU_REG4;
	   md[j+1]  = CFU_REG5;

	}

	ctx->byte_count = 0;
}

volatile uint16_t  md_wanted[8];
volatile uint16_t  md_currnt[8];
volatile uint8_t  str[64];
volatile uint32_t idx;
volatile struct md5_ctx ctx;

const char alphabet[] = "abcdefghijklmnopqrstuvwxyz";


bool equal(uint16_t *a, uint16_t *b, int32_t len) {
	int i;
	for (i=0; i < len; i++)
		if (a[i] != b[i])
			return false;
	return true;
}

void print_digest(uint16_t *data, uint32_t len) {
	uint32_t i;
	for (i=0; i< len; i++)
		neo430_uart_print_hex_word(data[i]);
}

bool bruteforce(int8_t depth, int8_t len)
{
	if (depth == len) {
		cfu_reset();
		md5_update(&ctx, str, len);
		md5_finalize(&ctx, md_currnt);
		if (equal(md_wanted , md_currnt, 8) ) {
			neo430_uart_br_print("\n\n=======================\n\n");
			neo430_uart_br_print("bruteforcing done \n\n");
			neo430_uart_br_print("found str: ");
			neo430_uart_br_print(str);
			neo430_uart_br_print("\n\n=======================\n\n");
			return true;
		}
		if (idx % 1000000 == 0) {
			neo430_uart_br_print("-- str: ");
			neo430_uart_br_print(str);
			neo430_uart_br_print(" hash:");
			print_digest(md_currnt, 8);
			neo430_uart_br_print("\n\n");
		}
		idx++;
		return false;
	}

	uint8_t i;
	for (i = 0; i < sizeof(alphabet); i++) {
		str[depth] = alphabet[i];
		if (bruteforce(depth + 1, len))
			return true;
	}
	return false;
}

void cracker(uint16_t wanted[8]) {
	idx = 0;
	md5_init(&ctx);
	int i;
	for (i=0; i < 8; i++)
		md_wanted[i] = wanted[i];

	for (i=0; i < 5; i++)
		if (bruteforce(0, i))
			break;
}

/* ------------------------------------------------------------
 * INFO Main function
 * ------------------------------------------------------------ */
int main(void) {

  // setup UART
  neo430_uart_setup(BAUD_RATE);

  // intro text
  neo430_uart_br_print("\nMD5 basic communication test program\n");

  // check if CFU present
  if (!(SYS_FEATURES & (1<<SYS_CFU_EN))) {
	neo430_uart_br_print("Error! No CFU synthesized!");
	return 1;
  }

  // wait for user to start
  neo430_uart_br_print("Press any key to start.\n\n");
  while (neo430_uart_char_received() == 0);


  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4|REG5 should be 6d64|3520\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0000;
  print_all_regs();

  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4|REG5 should be 6861|7368\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0001;
  print_all_regs();

  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4|REG5 should be 302e|3130\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0002;
  print_all_regs();


  //neo430_uart_br_print("MD5 short test vectors\n\n");
  //uint8_t str[] = "a";
  //neo430_uart_br_print("\'a\'  expected 0cc175b9c0f1b6a831c399e269772661\n\n");
  //md5_update(&ctx, str, 1);
  //md5_finalize(&ctx, md);
  struct md5_ctx ctx;
  uint16_t md[8] = {0};
  uint16_t md2[8] = {0};
  md5_init(&ctx);

  neo430_uart_br_print("MD5 short test vectors\n\n");
  uint8_t pwd[64] = "abc";
  cfu_reset();
  md5_update(&ctx, pwd, 3);
  md5_finalize(&ctx, md);

  neo430_uart_br_print("str: ");
  neo430_uart_br_print(pwd);
  neo430_uart_br_print(" hash:");
  print_digest(md, 8);
  neo430_uart_br_print("\n\n");

  neo430_uart_br_print("MD5 short test vectors\n\n");
  uint8_t pwd2[64] = "abc";
  cfu_reset();
  md5_update(&ctx, pwd2, 3);
  md5_finalize(&ctx, md2);

  neo430_uart_br_print("str: ");
  neo430_uart_br_print(pwd);
  neo430_uart_br_print(" hash:");
  print_digest(md2, 8);
  neo430_uart_br_print("\n\n");

  if (equal(md, md2, 8))
	  neo430_uart_br_print("\n\nequal\n\n");



  neo430_uart_br_print("Enter 128 bit hash (32 chars to try to break) \n\n");
  char input[64] = {};
  int16_t len;
  while ((len =neo430_uart_scan(&input, 64, 1) )== 0);

  cfu_reset();
  md5_update(&ctx, input, len);
  md5_finalize(&ctx, md);
  neo430_uart_br_print("\n\nhash: ");
  print_digest(md, 8);
  neo430_uart_br_print("\n\n");
  cracker(md);


  return 0;
}
