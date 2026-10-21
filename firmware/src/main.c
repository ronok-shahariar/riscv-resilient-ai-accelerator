// Copyright 2026 Md Shahariar Hassan
// SPDX-License-Identifier: Apache-2.0
// Original repository: https://github.com/ronok-shahariar/riscv-resilient-ai-accelerator

#include <stdint.h>

#define MAC_BASE         0x80000000u
#define UART_TX_ADDR     0x40000000u

#define MAC_ACTIVATION   (*(volatile uint32_t *)(MAC_BASE + 0x00u))
#define MAC_WEIGHT       (*(volatile uint32_t *)(MAC_BASE + 0x04u))
#define MAC_CONTROL      (*(volatile uint32_t *)(MAC_BASE + 0x08u))
#define MAC_STATUS       (*(volatile uint32_t *)(MAC_BASE + 0x0Cu))
#define MAC_RESULT       (*(volatile int32_t  *)(MAC_BASE + 0x10u))
#define MAC_FAULT_CONFIG (*(volatile uint32_t *)(MAC_BASE + 0x14u))
#define MAC_PROTECTION   (*(volatile uint32_t *)(MAC_BASE + 0x18u))
#define MAC_CLAMP_BOUND  (*(volatile int32_t  *)(MAC_BASE + 0x1Cu))

#define UART_TX_REG      (*(volatile uint32_t *)UART_TX_ADDR)

#define MAC_START        1u
#define MAC_CLEAR        2u
#define MAC_DONE         (1u << 0)
#define MAC_CLAMP_HIT    (1u << 1)

static void uart_putchar(char c)
{
    UART_TX_REG = (uint32_t)c;
}

static void uart_print(const char *s)
{
    while (*s) {
        uart_putchar(*s++);
    }
}

static void report(uint32_t code)
{
    if (code == 39u) {
        uart_print("\n[SUCCESS] All MAC operations passed! Final result: 39\n");
    } else {
        uart_print("\n[FAILURE] Test failed with code: 0x");
        for (int i = 7; i >= 0; i--) {
            uint32_t nibble = (code >> (i * 4)) & 0xFu;
            char c = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
            uart_putchar(c);
        }
        uart_print("\n");
    }

    for (;;) {
        __asm__ volatile ("nop");
    }
}

static void mac_accumulate(int8_t activation, int8_t weight)
{
    MAC_ACTIVATION = (uint32_t)(int32_t)activation;
    MAC_WEIGHT     = (uint32_t)(int32_t)weight;
    MAC_CONTROL    = MAC_START;

    while ((MAC_STATUS & MAC_DONE) == 0u) {
        // Wait for accelerator completion.
    }
}

int main(void)
{
    uart_print("\n--- PicoRV32 RISC-V SoC Booted ---\n");

    // =========================================================
    // Verify Week 3 MMIO Register Access
    // =========================================================
    MAC_FAULT_CONFIG = 0x3Bu; // Set fault test config
    if ((MAC_FAULT_CONFIG & 0xFFu) != 0x3Bu)
        report(0xBAD00010u);

    MAC_FAULT_CONFIG = 0u;    // Reset fault config

    MAC_CLAMP_BOUND  = 100;
    if (MAC_CLAMP_BOUND != 100)
        report(0xBAD00011u);

    MAC_PROTECTION   = 1u;
    if ((MAC_PROTECTION & 1u) != 1u)
        report(0xBAD00012u);

    MAC_PROTECTION   = 0u;    // Disable clamp for baseline

    // =========================================================
    // Three Verified Baseline MAC Operations (35 -> 23 -> 39)
    // =========================================================
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

    // All accelerator operations passed.
    report(39u);
}
