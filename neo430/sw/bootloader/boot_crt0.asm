; #################################################################################################
; #  < boot_crt0.asm - neo430 bootloader start-up code >                                          #
; # ********************************************************************************************* #
; # BSD 3-Clause License                                                                          #
; #                                                                                               #
; # Copyright (c) 2020, Stephan Nolting. All rights reserved.                                     #
; #                                                                                               #
; # Redistribution and use in source and binary forms, with or without modification, are          #
; # permitted provided that the following conditions are met:                                     #
; #                                                                                               #
; # 1. Redistributions of source code must retain the above copyright notice, this list of        #
; #    conditions and the following disclaimer.                                                   #
; #                                                                                               #
; # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
; #    conditions and the following disclaimer in the documentation and/or other materials        #
; #    provided with the distribution.                                                            #
; #                                                                                               #
; # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
; #    endorse or promote products derived from this software without specific prior written      #
; #    permission.                                                                                #
; #                                                                                               #
; # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
; # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
; # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
; # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
; # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
; # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
; # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
; # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
; # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
; # ********************************************************************************************* #
; # The NEO430 Processor - https://github.com/stnolting/neo430                                    #
; #################################################################################################

    .file	"boot_crt0.asm"
    .section .text
    .p2align 1,0

__boot_crt0:
; -----------------------------------------------------------
; Minimal required hardware setup
; -----------------------------------------------------------
  mov  #(0xC000-2), r1 ; = DMEM (RAM) base address
  add  &0xFFFA, r1 ; add DMEM (RAM) size in bytes to SP
  ;sub  #2, r1      ; address of last entry of stack (done in first instruction)

  
; -----------------------------------------------------------
; This is where the actual application is started
; -----------------------------------------------------------
  jmp  main ; do a simple jump - we are not coming back

.Lfe0:
    .size	__boot_crt0,.Lfe0-__boot_crt0
