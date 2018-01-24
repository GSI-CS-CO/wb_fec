#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include <stdint.h>
#include "mprintf.h"
#include "mini_sdb.h"
#include "irq.h"
#include "ebm.h"
#include "aux.h"
#include "dbg.h"


#define EBM_NOREPLY         1<<28
#define EBM_USEFEC          1<<24 

uint8_t cpuId, cpuQty;



void show_msi()
{
  mprintf(" Msg:\t%08x\nAdr:\t%08x\nSel:\t%01x\n", global_msi.msg, global_msi.adr, global_msi.sel);

}

void isr0()
{
   mprintf("ISR0\n");   
   show_msi();
}

void isr1()
{
   mprintf("ISR1\n");   
   show_msi();
}



void ebmInit()
{
  
   int j;
   
   while (*(pEbCfg + (EBC_SRC_IP>>2)) == EBC_DEFAULT_IP) {
     for (j = 0; j < (125000000/2); ++j) { asm("nop"); }
     mprintf("#%02u: Waiting for IP from WRC...\n", cpuId);  
   } 

   ebm_init();
   ebm_config_meta(1500, 42, EBM_NOREPLY | EBM_USEFEC);                             //MTU, max EB msgs, flags
   ebm_config_if(DESTINATION, 0xffffffffffff, 0xffffffff,                  0xebd0); //Dst: EB broadcast 
   ebm_config_if(SOURCE,      0xd15ea5edbeef, *(pEbCfg + (EBC_SRC_IP>>2)), 0xebd0); //Src: bogus mac (will be replaced by WR), WR IP

}


void init()
{ 

  discoverPeriphery();
  cpuId = getCpuIdx();

  uart_init_hw();   
  ebmInit();

  isr_table_clr();
  irq_set_mask(0x01);
  irq_disable();
   
}




void main(void) {
   
  int i,j;


  init();

  for (j = 0; j < ((125000000/4)+(cpuId*2500000)); ++j) { asm("nop"); }
  
    
  mprintf("#%02u: FEC Test Packet Gen Ready, sending ...\n", cpuId);
    
  
   while (1) {
    ebm_hi(0xaaa0);
    ebm_op(0xaaa0, i + 0, EBM_WRITE);
    ebm_op(0xaaa4, i + 1, EBM_WRITE);
    i += 2;
    ebm_flush();
    for (j = 0; j < ((125000000/4)); ++j) { asm("nop"); } 
  }
}
