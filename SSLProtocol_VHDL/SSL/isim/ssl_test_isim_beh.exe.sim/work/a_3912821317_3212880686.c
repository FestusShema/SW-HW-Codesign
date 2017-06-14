/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0xfbc00daa */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "/home/festus/Documents/SSL/SSL/outputcon.vhd";
extern char *IEEE_P_2592010699;

unsigned char ieee_p_2592010699_sub_2763492388968962707_503743352(char *, char *, unsigned int , unsigned int );


static void work_a_3912821317_3212880686_p_0(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    int t11;
    int t12;
    int t13;
    int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    int t18;
    int t19;
    int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;

LAB0:    xsi_set_current_line(28, ng0);
    t1 = (t0 + 1192U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 992U);
    t3 = ieee_p_2592010699_sub_2763492388968962707_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 2984);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(29, ng0);
    t1 = xsi_get_transient_memory(64U);
    memset(t1, 0, 64U);
    t5 = t1;
    memset(t5, (unsigned char)2, 64U);
    t6 = (t0 + 3064);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    t9 = (t8 + 56U);
    t10 = *((char **)t9);
    memcpy(t10, t1, 64U);
    xsi_driver_first_trans_fast_port(t6);
    goto LAB3;

LAB5:    xsi_set_current_line(31, ng0);
    t2 = (t0 + 4762);
    *((int *)t2) = 63;
    t5 = (t0 + 4766);
    *((int *)t5) = 0;
    t11 = 63;
    t12 = 0;

LAB7:    if (t11 >= t12)
        goto LAB8;

LAB10:    goto LAB3;

LAB8:    xsi_set_current_line(32, ng0);
    t6 = (t0 + 1352U);
    t7 = *((char **)t6);
    t6 = (t0 + 4762);
    t13 = *((int *)t6);
    t14 = (t13 - 63);
    t15 = (t14 * -1);
    xsi_vhdl_check_range_of_index(63, 0, -1, *((int *)t6));
    t16 = (1U * t15);
    t17 = (0 + t16);
    t8 = (t7 + t17);
    t4 = *((unsigned char *)t8);
    t9 = (t0 + 4762);
    t18 = *((int *)t9);
    t19 = (63 - t18);
    t20 = (t19 - 0);
    t21 = (t20 * 1);
    t22 = (1 * t21);
    t23 = (0U + t22);
    t10 = (t0 + 3064);
    t24 = (t10 + 56U);
    t25 = *((char **)t24);
    t26 = (t25 + 56U);
    t27 = *((char **)t26);
    *((unsigned char *)t27) = t4;
    xsi_driver_first_trans_delta(t10, t23, 1, 0LL);

LAB9:    t1 = (t0 + 4762);
    t11 = *((int *)t1);
    t2 = (t0 + 4766);
    t12 = *((int *)t2);
    if (t11 == t12)
        goto LAB10;

LAB11:    t13 = (t11 + -1);
    t11 = t13;
    t5 = (t0 + 4762);
    *((int *)t5) = t11;
    goto LAB7;

}


extern void work_a_3912821317_3212880686_init()
{
	static char *pe[] = {(void *)work_a_3912821317_3212880686_p_0};
	xsi_register_didat("work_a_3912821317_3212880686", "isim/ssl_test_isim_beh.exe.sim/work/a_3912821317_3212880686.didat");
	xsi_register_executes(pe);
}
