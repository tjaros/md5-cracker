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
#include <stdint.h>
#include <neo430.h>

// Configuration
#define BAUD_RATE 19200

void cfu_reset()
{
	CFU_REG0 = CFU_REG0  |  (1 << 14);
	CFU_REG0 = CFU_REG0  & ~(1 << 14);
}

void md5_alg_select()
{
	CFU_REG0 = 0x8001;
}

void cfu_alg_enable()
{
	CFU_REG0 = CFU_REG0 | (1 << 13);
}

void cfu_alg_disable()
{
	CFU_REG0 = CFU_REG0 & ~(1 << 13);
}

void md5_alg_write_enable()
{
	CFU_REG0 = CFU_REG0 | (1 << 12);
}

void md5_alg_write_disable()
{
	CFU_REG0 = CFU_REG0 & ~(1 << 12);
}

void md5_alg_init()
{
	md5_alg_select();
	cfu_reset();
	cfu_alg_enable();
}


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

  md5_alg_init();
  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4||REG5 should be 6d64|3520\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0000;
  print_all_regs();

  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4||REG5 should be 6861|7368\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0001;
  print_all_regs();

  neo430_uart_br_print("==========\n\n");
  neo430_uart_br_print("REG4||REG5 should be 302e|3130\n\n");
  neo430_uart_br_print("==========\n\n");
  CFU_REG1 = 0x0002;
  print_all_regs();



  return 0;
}
