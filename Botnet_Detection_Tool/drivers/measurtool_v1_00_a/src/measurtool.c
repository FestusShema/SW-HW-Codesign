//////////////////////////////////////////////////////////////////////////////
// Filename:          .../drivers/measurtool_v1_00_a/src/measurtool.c
// Version:           1.00.a
// Description:       measurtool Driver Source File
// Date:              Sun Feb 21 12:29:40 2010 (by Create and Import Peripheral Wizard)
// By:                University of Potsdam - Department of Computer Sceince 
//                    Ali Akbar Zarezadeh (akzare)
//////////////////////////////////////////////////////////////////////////////


/***************************** Include Files *******************************/

#include "measurtool.h"

/************************** Function Definitions ***************************/

/**
 *
 * Enable all possible interrupts from MEASURTOOL device.
 *
 * @param   baseaddr_p is the base address of the MEASURTOOL device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void MEASURTOOL_EnableInterrupt(void * baseaddr_p)
{
  uint32_t baseaddr;
  baseaddr = (uint32_t) baseaddr_p;

  /*
   * Enable all interrupt source from user logic.
   */
  MEASURTOOL_mWriteReg(baseaddr, MEASURTOOL_INTR_IPIER_OFFSET, 0xFFFFFFFF);

  /*
   * Enable all possible interrupt sources from device.
   */
  MEASURTOOL_mWriteReg(baseaddr, MEASURTOOL_INTR_DIER_OFFSET,
    INTR_TERR_MASK
    | INTR_DPTO_MASK
    | INTR_IPIR_MASK
    );

  /*
   * Set global interrupt enable.
   */
  MEASURTOOL_mWriteReg(baseaddr, MEASURTOOL_INTR_DGIER_OFFSET, INTR_GIE_MASK);
}

/**
 *
 * Example interrupt controller handler for MEASURTOOL device.
 * This is to show example of how to toggle write back ISR to clear interrupts.
 *
 * @param   baseaddr_p is the base address of the MEASURTOOL device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void MEASURTOOL_Intr_DefaultHandler(void * baseaddr_p)
{
  uint32_t baseaddr;
  uint32_t IntrStatus;
  uint32_t IpStatus;
  baseaddr = (uint32_t) baseaddr_p;

  /*
   * Get status from Device Interrupt Status Register.
   */
  IntrStatus = MEASURTOOL_mReadReg(baseaddr, MEASURTOOL_INTR_DISR_OFFSET);

  xil_printf("Device Interrupt! DISR value : 0x%08x \n\r", IntrStatus);

  /*
   * Verify the source of the interrupt is the user logic and clear the interrupt
   * source by toggle write baca to the IP ISR register.
   */
  if ( (IntrStatus & INTR_IPIR_MASK) == INTR_IPIR_MASK )
  {
    xil_printf("User logic interrupt! \n\r");
    IpStatus = MEASURTOOL_mReadReg(baseaddr, MEASURTOOL_INTR_IPISR_OFFSET);
    MEASURTOOL_mWriteReg(baseaddr, MEASURTOOL_INTR_IPISR_OFFSET, IpStatus);
  }

}

void MEASURTOOL_Intr_Handler(void * baseaddr_p)
{
	uint32_t baseaddr;
	uint32_t IntrStatus;
	uint32_t IpStatus;

	baseaddr = (uint32_t) baseaddr_p;

	/*
   * Get status from Device Interrupt Status Register.
   */
	IntrStatus = MEASURTOOL_mReadReg(baseaddr, MEASURTOOL_INTR_DISR_OFFSET);

//	xil_printf("Device Interrupt! DISR value : 0x%08x \n\r", IntrStatus);

	/*
	* Verify the source of the interrupt is the user logic and clear the interrupt
   * source by toggle write baca to the IP ISR register.
   */
	if ( (IntrStatus & INTR_IPIR_MASK) == INTR_IPIR_MASK )
	{
		
/*

    xil_printf("[C:%08X]", hw_regs->control_status_reg);
    
*/
		IpStatus = MEASURTOOL_mReadReg(baseaddr, MEASURTOOL_INTR_IPISR_OFFSET);
//    xil_printf("[ISR:%08X]", IpStatus);
    xil_printf("°");
		MEASURTOOL_mWriteReg(baseaddr, MEASURTOOL_INTR_IPISR_OFFSET, IpStatus);
		
	}
}