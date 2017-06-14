/*****************************************************************************
* Filename:          /home/jupiter/Desktop/Hard_ORB_Client_14.4_Virtex5/drivers/regperiph_v1_00_a/src/regperiph.h
* Version:           1.00.a
* Description:       regperiph Driver Header File
* Date:              Tue May 14 11:16:58 2013 (by Create and Import Peripheral Wizard)
*****************************************************************************/

#ifndef REGPERIPH_H
#define REGPERIPH_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xil_io.h"

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
 * -- SLV_REG8 : user logic slave module register 8
 * -- SLV_REG9 : user logic slave module register 9
 * -- SLV_REG10 : user logic slave module register 10
 * -- SLV_REG11 : user logic slave module register 11
 * -- SLV_REG12 : user logic slave module register 12
 * -- SLV_REG13 : user logic slave module register 13
 * -- SLV_REG14 : user logic slave module register 14
 * -- SLV_REG15 : user logic slave module register 15
 * -- SLV_REG16 : user logic slave module register 16
 * -- SLV_REG17 : user logic slave module register 17
 * -- SLV_REG18 : user logic slave module register 18
 * -- SLV_REG19 : user logic slave module register 19
 */
#define REGPERIPH_USER_SLV_SPACE_OFFSET (0x00000000)
#define REGPERIPH_SLV_REG0_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000000)
#define REGPERIPH_SLV_REG1_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000004)
#define REGPERIPH_SLV_REG2_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000008)
#define REGPERIPH_SLV_REG3_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x0000000C)
#define REGPERIPH_SLV_REG4_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000010)
#define REGPERIPH_SLV_REG5_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000014)
#define REGPERIPH_SLV_REG6_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000018)
#define REGPERIPH_SLV_REG7_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x0000001C)
#define REGPERIPH_SLV_REG8_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000020)
#define REGPERIPH_SLV_REG9_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000024)
#define REGPERIPH_SLV_REG10_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000028)
#define REGPERIPH_SLV_REG11_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x0000002C)
#define REGPERIPH_SLV_REG12_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000030)
#define REGPERIPH_SLV_REG13_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000034)
#define REGPERIPH_SLV_REG14_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000038)
#define REGPERIPH_SLV_REG15_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x0000003C)
#define REGPERIPH_SLV_REG16_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000040)
#define REGPERIPH_SLV_REG17_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000044)
#define REGPERIPH_SLV_REG18_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x00000048)
#define REGPERIPH_SLV_REG19_OFFSET (REGPERIPH_USER_SLV_SPACE_OFFSET + 0x0000004C)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a REGPERIPH register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the REGPERIPH device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void REGPERIPH_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define REGPERIPH_mWriteReg(BaseAddress, RegOffset, Data) \
 	Xil_Out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a REGPERIPH register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the REGPERIPH device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 REGPERIPH_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define REGPERIPH_mReadReg(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read 32 bit value to/from REGPERIPH user logic slave registers.
 *
 * @param   BaseAddress is the base address of the REGPERIPH device.
 * @param   RegOffset is the offset from the slave register to write to or read from.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note
 * C-style signature:
 * 	void REGPERIPH_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
 * 	Xuint32 REGPERIPH_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define REGPERIPH_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg3(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG3_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg4(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG4_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg5(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG5_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg6(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG6_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg7(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG7_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg8(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG8_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg9(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG9_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg10(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG10_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg11(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG11_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg12(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG12_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg13(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG13_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg14(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG14_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg15(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG15_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg16(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG16_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg17(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG17_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg18(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG18_OFFSET) + (RegOffset), (Xuint32)(Value))
#define REGPERIPH_mWriteSlaveReg19(BaseAddress, RegOffset, Value) \
 	Xil_Out32((BaseAddress) + (REGPERIPH_SLV_REG19_OFFSET) + (RegOffset), (Xuint32)(Value))

#define REGPERIPH_mReadSlaveReg0(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG0_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg1(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG1_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg2(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG2_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg3(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG3_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg4(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG4_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg5(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG5_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg6(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG6_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg7(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG7_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg8(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG8_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg9(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG9_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg10(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG10_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg11(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG11_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg12(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG12_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg13(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG13_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg14(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG14_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg15(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG15_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg16(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG16_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg17(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG17_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg18(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG18_OFFSET) + (RegOffset))
#define REGPERIPH_mReadSlaveReg19(BaseAddress, RegOffset) \
 	Xil_In32((BaseAddress) + (REGPERIPH_SLV_REG19_OFFSET) + (RegOffset))

/************************** Function Prototypes ****************************/


/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the REGPERIPH instance to be worked on.
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
XStatus REGPERIPH_SelfTest(void * baseaddr_p);

#endif /** REGPERIPH_H */
