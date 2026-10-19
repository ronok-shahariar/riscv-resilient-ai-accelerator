#include <stdint.h>

#define TEST_MMIO_ADDR 0x10000000u

int main(void)
{
    volatile uint32_t *mmio =
        (volatile uint32_t *)TEST_MMIO_ADDR;

    uint32_t a = 5;
    uint32_t b = 7;
    uint32_t result = a + b;

    *mmio = result;

    while (1) {
        __asm__ volatile ("nop");
    }
}
