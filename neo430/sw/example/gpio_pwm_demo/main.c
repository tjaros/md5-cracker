// #################################################################################################
// #  < Use the PWM controller to modulate the GPIO output port >                                  #
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
#define PWM_MAX   63


/* ------------------------------------------------------------
 * INFO Main function
 * ------------------------------------------------------------ */
int main(void) {

  // setup UART
  neo430_uart_setup(BAUD_RATE);

  neo430_uart_br_print("\n<<< PWM GPIO modulation demo >>>\n");

  // check if PWM unit was synthesized, exit if not
  if (!(SYS_FEATURES & (1<<SYS_PWM_EN))) {
    neo430_uart_br_print("Error! No PWM controller synthesized!");
    return 1;
  }

  // check if GPIO unit was synthesized, exit if not
  if (!(SYS_FEATURES & (1<<SYS_GPIO_EN))) {
    neo430_uart_br_print("Error! No GPIO controller synthesized!");
    return 1;
  }

  // enable pwm controller
  neo430_pwm_enable(PWM_PRSC_4, 1, 1); // 2nd highest frequency, 8-bit resolution, use GPIO modulation

  // clear GPIO output port
  neo430_gpio_port_set(0);

  // clear pwm channel 3 (GPIO PWM channel)
  neo430_pwm_set(0, 0);

  uint8_t pwm = 0;
  uint8_t up = 1;
  uint16_t cnt = 0;

  // animate!
  while(1) {
  
    // update duty cycle
    if (up) {
      if (pwm == (256/2)) // half max
        up = 0;
      else
        pwm++;
    }
    else {
      if (pwm == 0)
        up = 1;
      else
        pwm--;
    }

    // output new duty cycle
    neo430_pwm_set(3, pwm);

    // output simple counter on GPIO output port
    neo430_gpio_port_set((cnt>>4) & 0x00FF);
    cnt++;

    neo430_cpu_delay_ms(8);
  }

  return 0;
}
