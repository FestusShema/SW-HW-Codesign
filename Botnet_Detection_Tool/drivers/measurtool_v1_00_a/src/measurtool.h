//////////////////////////////////////////////////////////////////////////////
// Filename:          .../drivers/measurtool_v1_00_a/src/measurtool.h
// Version:           1.00.a
// Description:       measurtool Driver Header File
// Date:              Sun Feb 21 12:29:40 2010 (by Create and Import Peripheral Wizard)
// By:                University of Potsdam - Department of Computer Sceince 
//                    Ali Akbar Zarezadeh (akzare)
//////////////////////////////////////////////////////////////////////////////

#ifndef MEASURTOOL_H
#define MEASURTOOL_H

/***************************** Include Files *******************************/

//#include "xbasic_types.h"
//#include "xstatus.h"
//#include "xio.h"


#include <stdint.h>

#ifndef NULL
#define NULL		0
#endif

struct meastool_hw_regs_t {
  uint16_t magic;
  uint16_t hw_version;
  uint32_t counter_regs[];
} __attribute__ ((packed));

typedef volatile struct meastool_hw_regs_t meastool_hw_regs_t;

/************************** Constant Definitions ***************************/


/**
 * User Logic Slave Space Offsets
 * -- SLV_REG0 : user logic slave module register 0
 * -- SLV_REG1 : user logic slave module register 1
 * -- SLV_REG2 : user logic slave module register 2
 * -- SLV_REG3 : user logic slave module register 3
 * -- SLV_REG4 : user logic slave module register 4
 * -- SLV_REG5 : user logic slave module register 5
 * -- SLV_REG6 : user logic slave module register 6
 * -- SLV_REG7 : user logic slave module register 7
 */
#define MEASURTOOL_USER_SLV_SPACE_OFFSET (0x00000000)
#define MEASURTOOL_SLV_REG0_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000000)
#define MEASURTOOL_SLV_REG1_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000004)
#define MEASURTOOL_SLV_REG2_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000008)
#define MEASURTOOL_SLV_REG3_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x0000000C)
#define MEASURTOOL_SLV_REG4_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000010)
#define MEASURTOOL_SLV_REG5_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000014)
#define MEASURTOOL_SLV_REG6_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x00000018)
#define MEASURTOOL_SLV_REG7_OFFSET (MEASURTOOL_USER_SLV_SPACE_OFFSET + 0x0000001C)

/**
 * Interrupt Controller Space Offsets
 * -- INTR_DISR  : device (peripheral) interrupt status register
 * -- INTR_DIPR  : device (peripheral) interrupt pending register
 * -- INTR_DIER  : device (peripheral) interrupt enable register
 * -- INTR_DIIR  : device (peripheral) interrupt id (priority encoder) register
 * -- INTR_DGIER : device (peripheral) global interrupt enable register
 * -- INTR_ISR   : ip (user logic) interrupt status register
 * -- INTR_IER   : ip (user logic) interrupt enable register
 */
#define MEASURTOOL_INTR_CNTRL_SPACE_OFFSET (0x00000100)
#define MEASURTOOL_INTR_DISR_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000000)
#define MEASURTOOL_INTR_DIPR_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000004)
#define MEASURTOOL_INTR_DIER_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000008)
#define MEASURTOOL_INTR_DIIR_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000018)
#define MEASURTOOL_INTR_DGIER_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x0000001C)
#define MEASURTOOL_INTR_IPISR_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000020)
#define MEASURTOOL_INTR_IPIER_OFFSET (MEASURTOOL_INTR_CNTRL_SPACE_OFFSET + 0x00000028)

/**
 * Interrupt Controller Masks
 * -- INTR_TERR_MASK : transaction error
 * -- INTR_DPTO_MASK : data phase time-out
 * -- INTR_IPIR_MASK : ip interrupt requeset
 * -- INTR_RFDL_MASK : read packet fifo deadlock interrupt request
 * -- INTR_WFDL_MASK : write packet fifo deadlock interrupt request
 * -- INTR_IID_MASK  : interrupt id
 * -- INTR_GIE_MASK  : global interrupt enable
 * -- INTR_NOPEND    : the DIPR has no pending interrupts
 */
#define INTR_TERR_MASK (0x00000001UL)
#define INTR_DPTO_MASK (0x00000002UL)
#define INTR_IPIR_MASK (0x00000004UL)
#define INTR_RFDL_MASK (0x00000020UL)
#define INTR_WFDL_MASK (0x00000040UL)
#define INTR_IID_MASK (0x000000FFUL)
#define INTR_GIE_MASK (0x80000000UL)
#define INTR_NOPEND (0x80)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a MEASURTOOL register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the MEASURTOOL device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void MEASURTOOL_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
/*
#define MEASURTOOL_mWriteReg(BaseAddress, RegOffset, Data) \
 	XIo_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))
*/  
#define MEASURTOOL_mWriteReg(BaseAddress, RegOffset, Data) \
  { (*(volatile uint32_t *)((BaseAddress) + (RegOffset)) = (uint32_t)(Data)); }
  

/**
 *
 * Read a value from a MEASURTOOL register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the MEASURTOOL device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 MEASURTOOL_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
/*
#define MEASURTOOL_mReadReg(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (RegOffset))
*/
#define MEASURTOOL_mReadReg(BaseAddress, RegOffset) \
 	(*((volatile uint32_t *)((BaseAddress) + (RegOffset))))

/**
 *
 * Write/Read 32 bit value to/from MEASURTOOL user logic slave registers.
 *
 * @param   BaseAddress is the base address of the MEASURTOOL device.
 * @param   RegOffset is the offset from the slave register to write to or read from.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note
 * C-style signature:
 * 	void MEASURTOOL_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
 * 	Xuint32 MEASURTOOL_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
/* 
#define MEASURTOOL_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg3(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG3_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg4(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG4_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg5(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG5_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg6(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG6_OFFSET) + (RegOffset), (Xuint32)(Value))
#define MEASURTOOL_mWriteSlaveReg7(BaseAddress, RegOffset, Value) \
 	XIo_Out32((BaseAddress) + (MEASURTOOL_SLV_REG7_OFFSET) + (RegOffset), (Xuint32)(Value))

#define MEASURTOOL_mReadSlaveReg0(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG0_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg1(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG1_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg2(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG2_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg3(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG3_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg4(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG4_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg5(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG5_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg6(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG6_OFFSET) + (RegOffset))
#define MEASURTOOL_mReadSlaveReg7(BaseAddress, RegOffset) \
 	XIo_In32((BaseAddress) + (MEASURTOOL_SLV_REG7_OFFSET) + (RegOffset))
*/
/************************** Function Prototypes ****************************/


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
void MEASURTOOL_EnableInterrupt(void * baseaddr_p);

/**
 *
 * Example interrupt controller handler.
 *
 * @param   baseaddr_p is the base address of the MEASURTOOL device.
 *
 * @return  None.
 *
 * @note    None.
 *
 */
void MEASURTOOL_Intr_DefaultHandler(void * baseaddr_p);
void MEASURTOOL_Intr_Handler(void * baseaddr_p);

/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the MEASURTOOL instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
//XStatus MEASURTOOL_SelfTest(void * baseaddr_p);

#endif // MEASURTOOL_H
