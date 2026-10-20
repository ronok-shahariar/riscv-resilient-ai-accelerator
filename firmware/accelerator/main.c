// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

#include <stdint.h>

#define MAC_BASE        0x80000000u
#define TEST_OUTPUT     0x10000000u

#define MAC_ACTIVATION  (*(volatile uint32_t *)(MAC_BASE + 0x00u))
#define MAC_WEIGHT      (*(volatile uint32_t *)(MAC_BASE + 0x04u))
#define MAC_CONTROL     (*(volatile uint32_t *)(MAC_BASE + 0x08u))
#define MAC_STATUS      (*(volatile uint32_t *)(MAC_BASE + 0x0Cu))
#define MAC_RESULT      (*(volatile uint32_t *)(MAC_BASE + 0x10u))

#define MAC_START       1u
#define MAC_CLEAR       2u
#define MAC_DONE        1u

static void report(uint32_t code)
{
    *(volatile uint32_t *)TEST_OUTPUT = code;

    for (;;) {
        __asm__ volatile ("nop");
    }
}

static void mac_accumulate(int8_t activation, int8_t weight)
{
    MAC_ACTIVATION = (uint32_t)(int32_t)activation;
    MAC_WEIGHT = (uint32_t)(int32_t)weight;

    MAC_CONTROL = MAC_START;

    while ((MAC_STATUS & MAC_DONE) == 0u) {
        // Wait for accelerator completion.
    }
}

int main(void)
{
    MAC_CONTROL = MAC_CLEAR;

    mac_accumulate(5, 7);

    if ((int32_t)MAC_RESULT != 35)
        report(0xBAD00001u);

    mac_accumulate(-3, 4);

    if ((int32_t)MAC_RESULT != 23)
        report(0xBAD00002u);

    mac_accumulate(-8, -2);

    if ((int32_t)MAC_RESULT != 39)
        report(0xBAD00003u);

    // All three accelerator operations passed.
    report(39u);
}
