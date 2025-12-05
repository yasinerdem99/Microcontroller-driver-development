#include "Bootloader_flash.h"
#include <string.h>
#include <stdio.h>

/* NOT: Artık burada UART_HandleTypeDef veya huart1 YOK. */
/* Sadece Flash işlemleri var. */

/* STM32U5A9 (4MB Device) Sabitleri */
#define FLASH_BANK2_START_ADDR  0x08200000
#define APP_NUM_PAGES_TO_ERASE  128

/* --- RAM FUNCTION TANIMLAMASI --- */
#if defined (__GNUC__)
  #define __RAM_FUNC __attribute__((section(".RamFunc")))
#elif defined (__CC_ARM)
  #define __RAM_FUNC __attribute__((section("RamFunc")))
#endif

/**
  * @brief  Flash belleğe veri yazar (RAM'de çalışır, UART'tan bağımsız).
  */
__RAM_FUNC uint8_t Bootloader_Flash_Write(uint32_t address, uint8_t *data, uint16_t len)
{
    uint32_t temp_data[4];

    /* BURADAKİ UART BEKLEME DÖNGÜSÜNÜ KALDIRDIK */
    /* Bu sayede XMODEM etkilenmeyecek */

    __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_ALL_ERRORS);
    HAL_FLASH_Unlock();

    for (int i = 0; i < len; i += 16)
    {
        memset(temp_data, 0xFF, 16);
        uint16_t copy_len = (len - i) >= 16 ? 16 : (len - i);
        memcpy(temp_data, &data[i], copy_len);

        /* Kesmeleri Kapat (Kritik İşlem) */
        __disable_irq();
        HAL_StatusTypeDef status = HAL_FLASH_Program(FLASH_TYPEPROGRAM_QUADWORD, address + i, (uint32_t)temp_data);
        __enable_irq();

        if (status != HAL_OK)
        {
            HAL_FLASH_Lock();
            return 0;
        }
    }

    HAL_FLASH_Lock();
    return 1;
}

/**
  * @brief  Hedef slota ait sayfaları siler (RAM'de çalışır).
  */
__RAM_FUNC uint8_t Bootloader_Flash_Erase_Target_Slot(uint32_t slot_addr)
{
    FLASH_EraseInitTypeDef EraseInitStruct;
    uint32_t PageError;
    uint32_t StartPage;
    uint32_t BankNumber;

    /* BURADAKİ UART BEKLEME DÖNGÜSÜNÜ DE KALDIRDIK */

    if (slot_addr < FLASH_BANK2_START_ADDR)
    {
        BankNumber = FLASH_BANK_1;
        StartPage = (slot_addr - FLASH_BASE) / FLASH_PAGE_SIZE;
    }
    else
    {
        BankNumber = FLASH_BANK_2;
        StartPage = (slot_addr - FLASH_BANK2_START_ADDR) / FLASH_PAGE_SIZE;
    }

    HAL_FLASH_Unlock();
    __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_ALL_ERRORS);

    EraseInitStruct.TypeErase   = FLASH_TYPEERASE_PAGES;
    EraseInitStruct.Banks       = BankNumber;
    EraseInitStruct.Page        = StartPage;
    EraseInitStruct.NbPages     = APP_NUM_PAGES_TO_ERASE;

    __disable_irq();
    HAL_StatusTypeDef status = HAL_FLASHEx_Erase(&EraseInitStruct, &PageError);
    __enable_irq();

    if (status != HAL_OK)
    {
        HAL_FLASH_Lock();
        return 0;
    }

    /* Cache Temizliği */
    SCB_InvalidateICache();

    HAL_FLASH_Lock();
    return 1;
}
